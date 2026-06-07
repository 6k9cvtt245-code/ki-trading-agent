#!/usr/bin/env bash
# Trade-Execution bei Alpaca MIT HARTEN, IM CODE VERANKERTEN LIMITS.
#
# Das ist die eigentliche Sicherheitsschicht: Egal was der KI-Agent im Prompt
# "beschließt" – dieses Script prüft jede Order gegen die Risiko-Regeln und
# VERWEIGERT sie bei Verstoß. Code lügt nicht, ein LLM kann es.
#
# Aufruf:
#   ./alpaca-trade.sh buy  SYMBOL QTY STOP_PRICE [TARGET_PRICE]
#   ./alpaca-trade.sh sell SYMBOL QTY
#
# Beispiel (Kauf mit Pflicht-Stop-Loss + optionalem Ziel):
#   ./alpaca-trade.sh buy AAPL 3 185.00 210.00
#
# Bei KAUF wird eine Bracket-Order platziert: Markt-Entry + Stop-Loss
# (+ optionales Take-Profit-Ziel) in einem atomaren Auftrag. So kann nie
# eine Position ohne Absicherung entstehen.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_alpaca_common.sh
source "$DIR/_alpaca_common.sh"

check_env

SIDE="${1:-}"
SYMBOL="${2:-}"
QTY="${3:-}"

[ -n "$SIDE" ] && [ -n "$SYMBOL" ] && [ -n "$QTY" ] \
  || die "Aufruf: $0 buy|sell SYMBOL QTY [STOP_PRICE] [TARGET_PRICE]"

SYMBOL="$(echo "$SYMBOL" | tr '[:lower:]' '[:upper:]')"

# Hilfsfunktion für Float-Vergleiche.
fcmp() { awk "BEGIN{exit !($1)}"; }

# ── Konto-Kennzahlen holen ──
ACCOUNT="$(alpaca_get /v2/account)"
POSITIONS="$(alpaca_get /v2/positions)"
PORTFOLIO_VALUE="$(echo "$ACCOUNT" | jq -r '.portfolio_value')"
EQUITY="$(echo "$ACCOUNT" | jq -r '.equity')"
LAST_EQUITY="$(echo "$ACCOUNT" | jq -r '.last_equity')"
TRADING_BLOCKED="$(echo "$ACCOUNT" | jq -r '.trading_blocked')"

[ "$TRADING_BLOCKED" = "false" ] || die "Konto: Handel blockiert (trading_blocked=true)."

# ── LIMIT 0: Tages-Verlust-Cap ── (gilt für JEDEN Trade, zuerst geprüft)
DAILY_PNL_PCT="$(awk -v e="$EQUITY" -v l="$LAST_EQUITY" \
  'BEGIN { if (l+0==0) print 0; else printf "%.4f", (e-l)/l*100 }')"
if fcmp "$DAILY_PNL_PCT <= -$DAILY_LOSS_CAP_PCT"; then
  die "Tages-Verlust-Cap erreicht (${DAILY_PNL_PCT}% <= -${DAILY_LOSS_CAP_PCT}%). Heute KEINE Trades mehr."
fi

# ═══════════════════════════════════════════════
#  VERKAUF – schließt Position, kein Risiko-Check nötig
# ═══════════════════════════════════════════════
if [ "$SIDE" = "sell" ]; then
  BODY="$(jq -nc --arg s "$SYMBOL" --arg q "$QTY" \
    '{symbol:$s, qty:$q, side:"sell", type:"market", time_in_force:"day"}')"
  RESP="$(alpaca_post /v2/orders "$BODY")" || die "Verkaufs-Order fehlgeschlagen: $RESP"
  OID="$(echo "$RESP" | jq -r '.id // empty')"
  [ -n "$OID" ] || die "Verkauf abgelehnt: $RESP"
  echo "✅ VERKAUF platziert: $QTY x $SYMBOL (Order $OID)"
  echo "$RESP" | jq -c '{action:"sell", symbol, qty, order_id:.id, status, ts:now|todate}'
  exit 0
fi

[ "$SIDE" = "buy" ] || die "Unbekannte Seite '$SIDE' (erlaubt: buy|sell)."

# ═══════════════════════════════════════════════
#  KAUF – volle Risiko-Prüfung
# ═══════════════════════════════════════════════
STOP_PRICE="${4:-}"
TARGET_PRICE="${5:-}"

# ── LIMIT 1: Stop-Loss ist PFLICHT ──
[ -n "$STOP_PRICE" ] || die "Kauf ohne Stop-Loss ist verboten. Aufruf: $0 buy $SYMBOL $QTY STOP_PRICE [TARGET]"

# ── Aktuellen Kurs holen ──
PRICE="$(latest_price "$SYMBOL")"
fcmp "$PRICE > 0" || die "Ungültiger Kurs für $SYMBOL: $PRICE"

# Stop muss unter dem aktuellen Kurs liegen (Long-Position).
fcmp "$STOP_PRICE < $PRICE" || die "Stop-Loss ($STOP_PRICE) muss unter dem aktuellen Kurs ($PRICE) liegen."

# ── LIMIT 2: Max. offene Positionen ──
OPEN_COUNT="$(echo "$POSITIONS" | jq 'length')"
ALREADY_HELD="$(echo "$POSITIONS" | jq --arg s "$SYMBOL" 'map(.symbol)|index($s)|if .==null then 0 else 1 end')"
if [ "$ALREADY_HELD" -eq 0 ] && [ "$OPEN_COUNT" -ge "$MAX_OPEN_POSITIONS" ]; then
  die "Max. offene Positionen erreicht ($OPEN_COUNT/$MAX_OPEN_POSITIONS). Kein neuer Titel."
fi

# ── LIMIT 3: Positionsgröße (% des Portfolios) ──
POS_VALUE="$(awk -v q="$QTY" -v p="$PRICE" 'BEGIN{printf "%.2f", q*p}')"
POS_PCT="$(awk -v v="$POS_VALUE" -v pf="$PORTFOLIO_VALUE" 'BEGIN{if(pf+0==0){print 999}else printf "%.2f", v/pf*100}')"
if fcmp "$POS_PCT > $MAX_POSITION_STOCK_PCT"; then
  die "Position zu groß: \$$POS_VALUE = ${POS_PCT}% > Limit ${MAX_POSITION_STOCK_PCT}% des Portfolios."
fi

# ── LIMIT 4: Max. Verlust pro Trade (Stop-Distanz * Menge <= X% Portfolio) ──
RISK_AMOUNT="$(awk -v p="$PRICE" -v s="$STOP_PRICE" -v q="$QTY" 'BEGIN{printf "%.2f", (p-s)*q}')"
RISK_PCT="$(awk -v r="$RISK_AMOUNT" -v pf="$PORTFOLIO_VALUE" 'BEGIN{if(pf+0==0){print 999}else printf "%.2f", r/pf*100}')"
if fcmp "$RISK_PCT > $MAX_LOSS_PER_TRADE_PCT"; then
  die "Trade-Risiko zu hoch: \$$RISK_AMOUNT = ${RISK_PCT}% > Limit ${MAX_LOSS_PER_TRADE_PCT}% des Portfolios. Menge reduzieren oder Stop enger setzen."
fi

# ── LIMIT 5: Risk/Reward >= 2:1  (nur wenn Ziel angegeben) ──
if [ -n "$TARGET_PRICE" ]; then
  fcmp "$TARGET_PRICE > $PRICE" || die "Zielkurs ($TARGET_PRICE) muss über aktuellem Kurs ($PRICE) liegen."
  RR="$(awk -v t="$TARGET_PRICE" -v p="$PRICE" -v s="$STOP_PRICE" 'BEGIN{printf "%.2f", (t-p)/(p-s)}')"
  if fcmp "$RR < 2"; then
    die "Risk/Reward zu niedrig: ${RR}:1 < 2:1. Trade abgelehnt."
  fi
fi

# ── Genug Cash? ──
CASH="$(echo "$ACCOUNT" | jq -r '.cash')"
if fcmp "$POS_VALUE > $CASH"; then
  die "Nicht genug Cash: braucht \$$POS_VALUE, verfügbar \$$CASH."
fi

# ── Alle Checks bestanden → Bracket-Order bauen ──
echo "────────────────────────────────────────"
echo "  PRE-TRADE CHECK BESTANDEN: $SYMBOL"
echo "  Kurs aktuell:   \$$PRICE"
echo "  Menge:          $QTY  (Wert \$$POS_VALUE = ${POS_PCT}% Portfolio)"
echo "  Stop-Loss:      \$$STOP_PRICE  (Risiko \$$RISK_AMOUNT = ${RISK_PCT}%)"
[ -n "$TARGET_PRICE" ] && echo "  Ziel:           \$$TARGET_PRICE  (R/R ${RR}:1)"
echo "────────────────────────────────────────"

if [ -n "$TARGET_PRICE" ]; then
  BODY="$(jq -nc --arg s "$SYMBOL" --arg q "$QTY" --arg sp "$STOP_PRICE" --arg tp "$TARGET_PRICE" \
    '{symbol:$s, qty:$q, side:"buy", type:"market", time_in_force:"gtc",
      order_class:"bracket",
      stop_loss:{stop_price:$sp},
      take_profit:{limit_price:$tp}}')"
else
  # Ohne Ziel: OTO-Order (Entry + angehängter Stop-Loss).
  BODY="$(jq -nc --arg s "$SYMBOL" --arg q "$QTY" --arg sp "$STOP_PRICE" \
    '{symbol:$s, qty:$q, side:"buy", type:"market", time_in_force:"gtc",
      order_class:"oto",
      stop_loss:{stop_price:$sp}}')"
fi

RESP="$(alpaca_post /v2/orders "$BODY")" || die "Order-Request fehlgeschlagen: $RESP"
OID="$(echo "$RESP" | jq -r '.id // empty')"
[ -n "$OID" ] || die "Order abgelehnt von Alpaca: $RESP"

echo "✅ KAUF platziert: $QTY x $SYMBOL @ ~\$$PRICE (Order $OID, Stop \$$STOP_PRICE)"
# Kompakte JSON-Zeile fürs Trade-Log.
echo "$RESP" | jq -c \
  --arg price "$PRICE" --arg stop "$STOP_PRICE" --arg target "${TARGET_PRICE:-}" \
  --arg risk "$RISK_AMOUNT" --arg rpct "$RISK_PCT" \
  '{action:"buy", symbol, qty, est_entry:($price|tonumber),
    stop_loss:($stop|tonumber), target:($target),
    risk_eur:($risk|tonumber), risk_pct:($rpct|tonumber),
    order_id:.id, status, ts:now|todate}'

#!/usr/bin/env bash
# Marktdaten + einfache technische Indikatoren für ein Symbol (read-only).
# Liefert dem Agenten eine kompakte Analyse-Basis OHNE externe Research-API.
#
# Aufruf:  ./alpaca-bars.sh SYMBOL [TAGE]
# Default TAGE = 60 (Tageskerzen).
#
# Ausgabe: menschlich lesbar + kompakte JSON-Zeile mit:
#   last_close, sma20, sma50, high_20, low_20, trend, dist_sma50_pct

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_alpaca_common.sh
source "$DIR/_alpaca_common.sh"
check_env

SYMBOL="$(echo "${1:?Aufruf: $0 SYMBOL [TAGE]}" | tr '[:lower:]' '[:upper:]')"
DAYS="${2:-60}"

DATA_URL="https://data.alpaca.markets"
# Startdatum: genug Kalendertage zurück, um DAYS Handelstage zu bekommen
# (~Faktor 2 wegen Wochenenden/Feiertagen). Plattformübergreifend (macOS/Linux).
CAL_DAYS=$(( DAYS * 2 + 10 ))
START="$(date -v-${CAL_DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${CAL_DAYS} days ago" +%Y-%m-%d)"

# feed=iex = kostenloser Datenfeed (für Paper/Free-Accounts).
RESP="$(curl -sf \
  -H "APCA-API-KEY-ID: ${ALPACA_API_KEY}" \
  -H "APCA-API-SECRET-KEY: ${ALPACA_SECRET_KEY}" \
  "${DATA_URL}/v2/stocks/${SYMBOL}/bars?timeframe=1Day&start=${START}&limit=${DAYS}&feed=iex" \
  || die "Bars-Abfrage für $SYMBOL fehlgeschlagen.")"

N="$(echo "$RESP" | jq '.bars | length')"
[ "$N" -ge 20 ] || die "Zu wenig Daten für $SYMBOL ($N Kerzen). Symbol korrekt?"

# Alle Berechnungen in einem jq-Durchlauf.
read -r LAST SMA20 SMA50 HIGH20 LOW20 <<<"$(echo "$RESP" | jq -r '
  .bars | map(.c) as $c
  | ($c|length) as $n
  | ($c[-1]) as $last
  | ($c[-20:] | add / 20) as $sma20
  | (if $n>=50 then ($c[-50:]|add/50) else ($c|add/$n) end) as $sma50
  | ($c[-20:] | max) as $h20
  | ($c[-20:] | min) as $l20
  | "\($last) \($sma20) \($sma50) \($h20) \($l20)"')"

# Trend-Einschätzung.
fcmp() { awk "BEGIN{exit !($1)}"; }
if fcmp "$LAST > $SMA20" && fcmp "$SMA20 > $SMA50"; then
  TREND="aufwärts"
elif fcmp "$LAST < $SMA20" && fcmp "$SMA20 < $SMA50"; then
  TREND="abwärts"
else
  TREND="seitwärts"
fi
DIST_SMA50="$(awk -v l="$LAST" -v s="$SMA50" 'BEGIN{printf "%.2f", (l-s)/s*100}')"

printf 'Symbol: %s  (%s Kerzen, Feed iex)\n' "$SYMBOL" "$N"
printf '  Letzter Kurs: %s\n' "$LAST"
printf '  SMA20: %.2f   SMA50: %.2f   (Kurs %.2f%% zur SMA50)\n' "$SMA20" "$SMA50" "$DIST_SMA50"
printf '  20-Tage Hoch/Tief: %s / %s\n' "$HIGH20" "$LOW20"
printf '  Trend: %s\n' "$TREND"

jq -nc \
  --arg sym "$SYMBOL" --arg last "$LAST" --arg s20 "$SMA20" --arg s50 "$SMA50" \
  --arg h "$HIGH20" --arg l "$LOW20" --arg t "$TREND" --arg d "$DIST_SMA50" \
  '{symbol:$sym, last_close:($last|tonumber), sma20:($s20|tonumber),
    sma50:($s50|tonumber), high_20:($h|tonumber), low_20:($l|tonumber),
    trend:$t, dist_sma50_pct:($d|tonumber), ts:now|todate}'

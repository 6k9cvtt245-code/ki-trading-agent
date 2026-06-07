#!/usr/bin/env bash
# Read-only Portfolio-Abfrage bei Alpaca. Platziert KEINE Orders.
# Das ist dein erster, völlig risikofreier Test, ob Keys & Endpoint stimmen.
#
# Aufruf:  ./alpaca-portfolio.sh
# Ausgabe: Konto-Übersicht + offene Positionen, menschlich lesbar,
#          sowie eine kompakte JSON-Zeile am Ende (für die Memory-Files).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_alpaca_common.sh
source "$DIR/_alpaca_common.sh"

check_env

ACCOUNT="$(alpaca_get /v2/account)"
POSITIONS="$(alpaca_get /v2/positions)"

EQUITY="$(echo "$ACCOUNT" | jq -r '.equity')"
LAST_EQUITY="$(echo "$ACCOUNT" | jq -r '.last_equity')"
CASH="$(echo "$ACCOUNT" | jq -r '.cash')"
PORTFOLIO_VALUE="$(echo "$ACCOUNT" | jq -r '.portfolio_value')"
STATUS="$(echo "$ACCOUNT" | jq -r '.status')"

# Tages-P&L in Prozent (gegen gestrigen Schlusswert).
DAILY_PNL_PCT="$(awk -v e="$EQUITY" -v l="$LAST_EQUITY" \
  'BEGIN { if (l+0==0) print 0; else printf "%.2f", (e-l)/l*100 }')"

OPEN_COUNT="$(echo "$POSITIONS" | jq 'length')"

echo "════════════════════════════════════════"
echo "  ALPACA PORTFOLIO  ($ALPACA_BASE_URL)"
echo "════════════════════════════════════════"
echo "Konto-Status:     $STATUS"
echo "Portfolio-Wert:   \$$PORTFOLIO_VALUE"
echo "Equity:           \$$EQUITY"
echo "Cash:             \$$CASH"
echo "Tages-P&L:        ${DAILY_PNL_PCT}%"
echo "Offene Positionen: $OPEN_COUNT / $MAX_OPEN_POSITIONS"
echo "────────────────────────────────────────"

if [ "$OPEN_COUNT" -gt 0 ]; then
  echo "$POSITIONS" | jq -r '.[] |
    "  \(.symbol): \(.qty) Stk @ \(.avg_entry_price) | aktuell \(.current_price) | P&L \(.unrealized_plpc|tonumber*100|.*100|round/100)%"'
else
  echo "  (keine offenen Positionen)"
fi
echo "════════════════════════════════════════"

# Kompakte JSON-Zeile (für memory/portfolio.md o.ä.)
echo "$ACCOUNT" | jq -c \
  --argjson pos "$POSITIONS" \
  --arg pnl "$DAILY_PNL_PCT" \
  '{ts: now|todate, status: .status, portfolio_value: .portfolio_value,
    cash: .cash, equity: .equity, daily_pnl_pct: ($pnl|tonumber),
    open_positions: ($pos|length),
    positions: [$pos[] | {symbol, qty, avg_entry_price, current_price, unrealized_plpc}]}'

#!/usr/bin/env bash
# Gemeinsame Hilfsfunktionen für alle Alpaca-Scripts.
# Wird via `source` eingebunden, nicht direkt ausgeführt.
#
# Erwartete Environment-Variablen (NIEMALS in Dateien speichern):
#   ALPACA_API_KEY     – API Key ID
#   ALPACA_SECRET_KEY  – Secret Key
#   ALPACA_BASE_URL    – z.B. https://paper-api.alpaca.markets  (Paper)
#                        oder https://api.alpaca.markets        (Live)
#
# Risiko-Limits (überschreibbar via ENV, sonst Defaults aus CLAUDE.md):
#   MAX_LOSS_PER_TRADE_PCT   Default 2   (% des Portfolios)
#   DAILY_LOSS_CAP_PCT       Default 5   (% des Portfolios)
#   MAX_POSITION_STOCK_PCT   Default 15  (% des Portfolios je Aktie)
#   MAX_OPEN_POSITIONS       Default 8

set -euo pipefail

# ---- Limits (Defaults) ----
MAX_LOSS_PER_TRADE_PCT="${MAX_LOSS_PER_TRADE_PCT:-2}"
DAILY_LOSS_CAP_PCT="${DAILY_LOSS_CAP_PCT:-5}"
MAX_POSITION_STOCK_PCT="${MAX_POSITION_STOCK_PCT:-15}"
MAX_OPEN_POSITIONS="${MAX_OPEN_POSITIONS:-8}"

# ---- Fehler-Helfer ----
die() { echo "❌ FEHLER: $*" >&2; exit 1; }
info() { echo "ℹ️  $*" >&2; }

# ---- ENV-Check ----
check_env() {
  [ -n "${ALPACA_API_KEY:-}" ]    || die "ALPACA_API_KEY ist nicht gesetzt."
  [ -n "${ALPACA_SECRET_KEY:-}" ] || die "ALPACA_SECRET_KEY ist nicht gesetzt."
  [ -n "${ALPACA_BASE_URL:-}" ]   || die "ALPACA_BASE_URL ist nicht gesetzt (Paper: https://paper-api.alpaca.markets)."

  # Sicherheitsnetz: warnen wenn Live-Endpoint aktiv ist.
  case "$ALPACA_BASE_URL" in
    *paper-api*) : ;;  # Paper, alles gut
    *) echo "⚠️  ACHTUNG: LIVE-Endpoint aktiv ($ALPACA_BASE_URL) – es wird mit echtem Geld gehandelt!" >&2 ;;
  esac
}

# ---- Authentifizierter GET ----
alpaca_get() {
  # $1 = Pfad, z.B. /v2/account
  curl -sf \
    -H "APCA-API-KEY-ID: ${ALPACA_API_KEY}" \
    -H "APCA-API-SECRET-KEY: ${ALPACA_SECRET_KEY}" \
    "${ALPACA_BASE_URL}$1" \
    || die "GET $1 fehlgeschlagen (Keys/Endpoint prüfen)."
}

# ---- Authentifizierter POST (JSON) ----
alpaca_post() {
  # $1 = Pfad, $2 = JSON-Body
  curl -sf -X POST \
    -H "APCA-API-KEY-ID: ${ALPACA_API_KEY}" \
    -H "APCA-API-SECRET-KEY: ${ALPACA_SECRET_KEY}" \
    -H "Content-Type: application/json" \
    -d "$2" \
    "${ALPACA_BASE_URL}$1"
}

# ---- Aktuellen Kurs (letzter Trade) holen ----
# Nutzt die Daten-API (separater Host). Gibt nur die Zahl aus.
latest_price() {
  # $1 = Symbol
  local data_url="https://data.alpaca.markets"
  curl -sf \
    -H "APCA-API-KEY-ID: ${ALPACA_API_KEY}" \
    -H "APCA-API-SECRET-KEY: ${ALPACA_SECRET_KEY}" \
    "${data_url}/v2/stocks/$1/trades/latest" \
    | jq -r '.trade.p' \
    || die "Kursabfrage für $1 fehlgeschlagen."
}

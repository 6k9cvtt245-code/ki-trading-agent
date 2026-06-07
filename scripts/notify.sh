#!/usr/bin/env bash
# Sendet eine Nachricht via Telegram-Bot.
#
# ENV (niemals in Dateien):
#   TELEGRAM_BOT_TOKEN  – vom @BotFather
#   TELEGRAM_CHAT_ID    – deine Chat-ID
#
# Aufruf:
#   ./notify.sh "Mein Text"
#   echo "Mehrzeiliger Text" | ./notify.sh

set -euo pipefail
die() { echo "❌ FEHLER: $*" >&2; exit 1; }

[ -n "${TELEGRAM_BOT_TOKEN:-}" ] || die "TELEGRAM_BOT_TOKEN nicht gesetzt."
[ -n "${TELEGRAM_CHAT_ID:-}" ]   || die "TELEGRAM_CHAT_ID nicht gesetzt."

if [ "$#" -gt 0 ]; then
  MSG="$*"
else
  MSG="$(cat)"
fi
[ -n "$MSG" ] || die "Leere Nachricht."

RESP="$(curl -sf -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${MSG}" \
  -d "parse_mode=HTML" \
  -d "disable_web_page_preview=true" \
  || die "Telegram-Senden fehlgeschlagen (Token/Chat-ID prüfen).")"

if [ "$(echo "$RESP" | jq -r '.ok')" != "true" ]; then
  die "Telegram-API meldete Fehler: $RESP"
fi
echo "✅ Telegram-Nachricht gesendet."

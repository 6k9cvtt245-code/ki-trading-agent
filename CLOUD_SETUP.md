# Cloud-Autopilot einrichten (Claude Desktop App)

Dieser Schritt passiert in der **Claude Desktop App** unter „Routines" (Remote).
Voraussetzung: Ein Claude-Plan, der Remote-Routinen unterstützt.

## 1. GitHub verbinden
- Claude Desktop → Routines → New Routine → **Remote**
- GitHub-Konto verbinden und Repo wählen: **6k9cvtt245-code/ki-trading-agent**

## 2. Cloud Environment anlegen
- Cloud Environments → Add Environment
- Name: `trading`
- Network Access: **Full**
- Environment Variables (Werte aus deiner lokalen `.env` — NIE in Dateien/GitHub):
  - `ALPACA_API_KEY`
  - `ALPACA_SECRET_KEY`
  - `ALPACA_BASE_URL`  = `https://paper-api.alpaca.markets`
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`

## 3. Tägliche Routine
- Cloud Environment: `trading`
- Repo: 6k9cvtt245-code/ki-trading-agent
- Modell: Claude Opus (neueste Version)
- Prompt: **„Folge exakt den Anweisungen in routines/taeglich.md"**
- Cron (Werktags): siehe unten
- „Allow unrestricted branch pushes" aktivieren (damit Memory zurückgepusht wird)

## 4. Wochen-Review (optional)
- Prompt: **„Folge exakt den Anweisungen in routines/wochen-review.md"**
- Cron: Freitags

## Cron-Zeiten (ACHTUNG Zeitzone prüfen!)
US-Börse öffnet 9:30 ET. Für eine Analyse nach Öffnung:
- Täglich Mo–Fr, ca. 16:00 deutscher Zeit
- Freitags zusätzlich Wochen-Review am Abend
Prüfe in den Routine-Einstellungen, in welcher Zeitzone der Cron läuft
(UTC vs. lokal) und passe die Stunde entsprechend an.

## Wichtig
- Modus bleibt PAPER. Die Routine HANDELT NICHT selbst — sie schickt nur
  Vorschläge per Telegram (siehe routines/taeglich.md). Du entscheidest.
- Beim Wechsel auf echtes Geld später: nur `ALPACA_BASE_URL` ändern
  (auf `https://api.alpaca.markets`).

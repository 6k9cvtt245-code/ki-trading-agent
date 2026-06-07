# Setup & Test — KI-Trading-Agent (Alpaca, Paper-Phase)

Stand: Phase „Alpaca-Scripts". Krypto/Binance bewusst noch NICHT dabei.
Modus: **Paper Trading** (kein echtes Geld). Live erst nach Systemtest.

## 1. Alpaca Paper-API-Keys holen
1. Einloggen auf https://app.alpaca.markets → oben rechts auf **Paper** umschalten.
2. Rechts: **Home → API Keys → Generate New Key** (für Paper-Konto).
3. Du erhältst `API Key ID` und `Secret Key`. Das Secret ist **nur einmal sichtbar**.

## 2. Keys NUR als Environment-Variablen setzen (nie in Dateien!)
Im Terminal, für den lokalen Test:

```bash
export ALPACA_API_KEY="dein_key_id"
export ALPACA_SECRET_KEY="dein_secret"
export ALPACA_BASE_URL="https://paper-api.alpaca.markets"
```

> Diese `export`-Zeilen gelten nur für die aktuelle Terminal-Sitzung.
> Schreibe sie NICHT in eine Datei, die im Git-Repo landet.

## 3. Erster, risikofreier Test (read-only)
```bash
cd ~/ki-trading-agent
./scripts/alpaca-portfolio.sh
```
Erwartung: Konto-Übersicht mit ~100.000 $ Paper-Kapital, 0 offene Positionen.
Wenn das klappt → Keys & Endpoint stimmen.

## 4. Trade-Script testen (Paper, mit echten Limits)
Beispiel-Kauf MIT Pflicht-Stop-Loss und Ziel:
```bash
./scripts/alpaca-trade.sh buy AAPL 3 185.00 210.00
```
Das Script lehnt automatisch ab, wenn:
- kein Stop-Loss angegeben ist
- die Position > 15 % des Portfolios wäre
- das Trade-Risiko > 2 % des Portfolios wäre
- das Risk/Reward < 2:1 ist (wenn Ziel angegeben)
- bereits 8 Positionen offen sind
- der Tages-Verlust schon ≤ -5 % ist

Verkauf:
```bash
./scripts/alpaca-trade.sh sell AAPL 3
```

## Risiko-Limits anpassen (optional)
Über ENV überschreibbar, Defaults stammen aus CLAUDE.md:
```bash
export MAX_LOSS_PER_TRADE_PCT=2
export DAILY_LOSS_CAP_PCT=5
export MAX_POSITION_STOCK_PCT=15
export MAX_OPEN_POSITIONS=8
```

## Noch offen (kommt in späteren Schritten)
- [ ] CLAUDE.md (Agenten-Regeln) + memory/-Dateien
- [ ] Research-Quelle: Perplexity-Key ODER Alpaca-Marktdaten — noch zu entscheiden
- [ ] Notifications: Telegram-Bot — Key fehlt noch
- [ ] Routinen (Cron) — erst nachdem Scripts lokal sauber laufen

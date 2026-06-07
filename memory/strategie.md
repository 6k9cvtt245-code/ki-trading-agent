# Handelsstrategie

> Lebendiges Dokument. Der Agent verfeinert es in den Wochen-Reviews.
> Aktueller Stand: Start der 4-Wochen-Paper-Phase. Nur Alpaca (Aktien/ETF).

## Ziel
Diszipliniertes Swing-Trading: Trend erkennen, einsteigen, mit Stop-Loss
absichern, Gewinne laufen lassen. Kein Markttiming, kein Day-Trading.
Renditeziel wird NACH der Paper-Phase datenbasiert festgelegt — nicht geraten.

## Kontogröße & Ordergröße ($500, BRUCHTEILE)
- Konto ist klein ($500). Gehandelt wird mit BRUCHTEIL-Anteilen (fractional),
  weil ganze ETF-Anteile (>$300) das 15%-Limit (~$75) sprengen würden.
- Positionsgröße in DOLLAR denken: max ~$75 pro Position (15% von $500).
- WICHTIG: Bei Bruchteilen gibt es KEINEN automatischen Börsen-Stop-Loss.
  → Stop-Loss ist "weich": Der Agent notiert ihn in memory/portfolio.md und
    prüft TÄGLICH den Kurs. Liegt der Kurs <= Stop, schlägt er VERKAUF vor.
  → Risiko: Bei schnellen Stürzen zwischen den Tagesläufen greift der Stop
    verzögert. In der Paper-Phase akzeptiert; vor Echtgeld neu bewerten.
- Kauf-Aufruf (Bruchteil): ./scripts/alpaca-trade.sh buy SYMBOL 0.1 STOP [ZIEL]
  (Menge mit Punkt = Bruchteil → einfache Markt-Order ohne Börsen-Stop.)

## Research-Ansatz (täglich)
1. Makro-Lage: Zinsen, Inflation, Fed/EZB-Signale.
2. Sentiment: Fear & Greed Index, allgemeine Risikostimmung.
3. News-Scan: Was bewegt heute die Märkte?
4. Watchlist prüfen: Gibt es Setup-Signale?
5. Anstehende Risiken: Wirtschaftsdaten, Earnings der Watchlist-Titel.

## Entscheidungsmatrix Kauf (ALLE drei müssen stimmen)
- [ ] Übergeordneter Trend intakt (Wochen-/Tageschart)
- [ ] Kurzfristige Korrektur/Konsolidierung abgeschlossen
- [ ] News/Sentiment stützen die Richtung

Für JEDEN geplanten Trade explizit berechnen:
Stop-Loss-Kurs · Zielkurs · Risk/Reward. Nur R/R ≥ 2:1 kommt in den Plan.

## Verkaufssignale
- Stop-Loss ausgelöst (automatisch via Bracket-Order)
- Zielkurs erreicht
- Fundamentale Lage kippt negativ
- Deutlich bessere Opportunität gefunden

## ETF-Watchlist (Kern, US-handelbar via Alpaca)
- VTI / ITOT  (US Total Market)
- VOO / SPY   (S&P 500)
- QQQ         (Nasdaq 100)
- (Agent ergänzt laufend)

## Aktien-Watchlist
- (Agent befüllt basierend auf Research)

## Krypto-Watchlist
- NICHT angebunden. Nur Vorschläge mit datierten Quellen an den Nutzer
  (siehe CLAUDE.md → Krypto-Regel). Keine eigenständigen Krypto-Trades.

## Lessons Learned
- **KW 23:** Infrastruktur-Check bestanden (API, Scripts). Tagesroutinen fehlen noch — ohne tägliche Research-Läufe keine Handelsentscheidungen möglich. Priorität: Tagesroutine als Scheduled Task aktivieren.

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
1. Makro-Lage: Zinsen, Inflation, Fed + EZB-Signale, EUR/USD-Entwicklung.
2. Sentiment: Fear & Greed Index, allgemeine Risikostimmung.
3. News-Scan: Was bewegt heute die Märkte? (US + EU)
4. Watchlist prüfen: Gibt es Setup-Signale? (inkl. EWG/VGK für EU-Exposure)
5. Anstehende Risiken: Wirtschaftsdaten, Earnings der Watchlist-Titel,
   EZB-Sitzungen, Bundesbank-Statements, EU-Wirtschaftsdaten (BIP, CPI).

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

### US-Markt
- VTI / ITOT  (US Total Market)
- VOO / SPY   (S&P 500)
- QQQ         (Nasdaq 100)

### Europa / Deutschland (US-gelistete ETFs, bilden EU-Märkte ab)
- EWG         (iShares MSCI Germany — DAX/MDAX-Exposure via Alpaca)
- VGK         (Vanguard FTSE Europe — breites EU-Exposure)
  Hinweis: Diese ETFs bilden den EU-Markt ab, handeln aber in USD auf US-Börsen.
  Kurs folgt DAX/EUR-Entwicklung + EUR/USD-Währungseffekt. Beide täglich prüfen.

- (Agent ergänzt laufend)

## Aktien-Watchlist

> Quellen: Quiver Quantitative (STOCK Act Daten 2025–2026), The BRRR (Jun 2026),
> Capitol Trades. Hinweis: Alle Kongress-Daten haben 30–45 Tage Verzug.
> Kein blindes Kopieren — nur ein Faktor unter vielen. Agent prüft täglich technisch.

### AI / Halbleiter (Kongress-Sektor #1, 34% der Käufe)
- **NVDA** (Nvidia)
  Begründung: Kongress-Kauf #1 (~$5,2M Mai–Jul 2025, Quelle: Quiver Quant).
  Fundamental: AI-Capex-Boom, Rechenzentren. Volatil → Swing-Setups möglich.
  Caveat: Hoch bewertet, anfällig für Korrekturen bei Fed-Signalen.

- **MSFT** (Microsoft)
  Begründung: Kontinuierlich im Kongress-Portfolio (Pelosi u.a.). AI-Infrastruktur
  (Azure, Copilot). Blue Chip, relativ stabil → gut für ersten Trade.
  Caveat: Weniger volatile = kleinere Swing-Amplituden.

- **GOOGL** (Alphabet)
  Begründung: Meistgekauft nach Transaktionszahl (180 Käufe/$3,5M+, Quiver Quant).
  AI (Gemini, Search, Cloud). Aktuell auch im Tech-Aufwärtstrend.
  Caveat: Regulierungsrisiko (EU/US Kartellverfahren laufend) beobachten.

- **MU** (Micron Technology)
  Begründung: 128 Kongress-Käufe/$714K (Quiver Quant). AI-Speicher-Demand
  (HBM-Chips für KI-Training). Mehr Volatilität als MSFT → bessere R/R-Setups.
  Caveat: Zyklisch — Chip-Überkapazitäten möglich. Nur bei klarem Aufwärtstrend.

- **TSM** (Taiwan Semiconductor, US ADR: TSM)
  Begründung: 39 Kongress-Käufe/$1,3M+ (Quiver Quant). Weltgrößter Chip-Auftragsfertiger.
  Caveat: TAIWAN-RISIKO (geopolitische Spannungen China/Taiwan). Vor jedem
  Kauf aktuelle Lage prüfen. Nur wenn Risiko gering und Trend klar aufwärts.

### Verteidigung / Defense (Kongress-Sektor #2, 22% — Surge nach Hormuz 2026)
- **RTX** (Raytheon Technologies)
  Begründung: Defense-Buying-Surge nach Hormuz-Spannungen (The BRRR, Jun 2026).
  Crenshaw, Green u.a. aktiv. RTX günstiger als LMT → besser für $500-Konto.
  Caveat: Geopolitische Lage täglich prüfen. Keine Position wenn Spannungen sich
  entspannen (Defense-Titel verlieren dann schnell).

### Energie (Kongress-Sektor #3, 18%)
- **XOM** (ExxonMobil)
  Begründung: 60 Kongress-Käufe/$979K (Quiver Quant). Ölpreis-Hedge.
  Caveat: Trotz grüner Rhetorik kauft Kongress Öl — struktureller Hinweis.
  Ölpreis + geopolitische Lage täglich als Kontext beachten.

### Nicht auf Watchlist (bewusste Entscheidung)
- AAPL: Kongress verkauft (erscheint in Top-Sales-Liste). Kein Kauf-Signal.
- META: Kongress verkauft Social Media (Regulierungsdruck erwartet lt. Berichten).
- LMT: Defense-Kauf, aber Kurs >$500 → zu teuer auch für Bruchteil-Sizing sinnvoll.

## Krypto-Watchlist
- NICHT angebunden. Nur Vorschläge mit datierten Quellen an den Nutzer
  (siehe CLAUDE.md → Krypto-Regel). Keine eigenständigen Krypto-Trades.

## Lessons Learned
- **KW 23:** Infrastruktur-Check bestanden (API, Scripts). Tagesroutinen fehlen noch — ohne tägliche Research-Läufe keine Handelsentscheidungen möglich. Priorität: Tagesroutine als Scheduled Task aktivieren.

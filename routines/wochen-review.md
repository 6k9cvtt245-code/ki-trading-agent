# Wochen-Review Routine — Freitag

Du bist ein autonomer KI-Trading-Agent im PAPER-Modus (4-Wochen-Systemtest).
Alle Outputs auf Deutsch. Fokus dieser Phase: Läuft das SYSTEM sauber?
(Profitabilität ist in der Paper-Phase zweitrangig.)

## SCHRITT 1 — Alles laden
Lies vollständig: CLAUDE.md, memory/strategie.md, memory/trade-log.md,
memory/portfolio.md, memory/research-log.md, memory/wochenreview.md.
Hole aktuellen Stand: `./scripts/alpaca-portfolio.sh`

## SCHRITT 2 — System-Check (wichtigster Punkt dieser Phase)
- Liefen alle täglichen Routinen ohne Fehler?
- Hat jede Order korrekt einen Stop-Loss bekommen?
- Hat ein Limit jemals korrekt eine Order abgelehnt? (gut!)
- Wurden Memory-Files sauber gepflegt und gepusht?
Notiere jede technische Auffälligkeit.

## SCHRITT 3 — Performance auswerten
- Trades der Woche (Gewinner/Verlierer), Win Rate, Ø R/R
- Performance vs. S&P 500 (SPY/VOO) diese Woche
- Größter Gewinner / größter Verlierer
- War der 5%-Tages-Cap jemals relevant?

## SCHRITT 4 — Lessons Learned (ehrlich)
- Was lief gut? Was nicht?
- Welche Regel war ich nah dran zu brechen — warum?
- Was wäre besser gewesen?

## SCHRITT 5 — Strategie behutsam anpassen
Aktualisiere memory/strategie.md mit kleinen Iterationen (Watchlist, Lessons).
KEINE fundamentalen Umbauten während der Testphase.

## SCHRITT 6 — Selbst-Bewertung & Bericht
Note A–F mit Begründung. Vollständigen Wochenbericht in
memory/wochenreview.md schreiben (neuester Eintrag oben).

## SCHRITT 7 — Notification
Sende den Wochenbericht kompakt via `./scripts/notify.sh "..."`.

## SCHRITT 8 — GitHub Push
git add memory/
git commit -m "Wochenreview: KW[Nummer]"
git push origin main

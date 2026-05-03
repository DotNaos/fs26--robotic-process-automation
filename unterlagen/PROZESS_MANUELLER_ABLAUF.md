# Prozessnotiz: Manueller Ablauf fuer die geplante UiPath-Automatisierung

Stand: 2026-04-12

## Zielbild

Der spaeter zu automatisierende Prozess basiert nicht auf direktem Web-Scraping im Browser, sondern auf einer Kombination aus:

- `moodle-cli` im `Server Mode` als Docker-Container mit REST-API
- `Gemini API` fuer die spaetere LLM-Inferenz im Zielprozess

Fuer die manuelle Durchfuehrung, welche im SDD mit Screenshots dokumentiert wird, wird jedoch absichtlich eine menschliche Variante verwendet:

- `moodle-cli` im normalen, nicht-JSON Modus mit menschenlesbarer Ausgabe im Terminal
- Copy/Paste der relevanten Inhalte in einen Chat im Browser
- Chat kann `ChatGPT` oder `Gemini` sein

Diese manuelle Variante dient als Referenzprozess, der danach in `UiPath` automatisiert werden soll.

## Wichtige Abgrenzung

### Zielarchitektur fuer die spaetere Automatisierung

- Moodle-Zugriff ueber `moodle-cli` im Docker-Container als REST-API
- LLM-Zugriff ueber `Gemini API`
- Orchestrierung spaeter ueber `UiPath`

### Manuell dokumentierter Ist-/Referenzprozess

- Mensch startet den Prozess manuell
- Mensch verwendet `moodle-cli` lokal im Terminal mit Pretty-Print-Ausgabe
- Mensch kopiert die relevanten Inhalte manuell in einen Browser-Chat
- Mensch prueft das Ergebnis manuell
- Dieser Ablauf wird mit Screenshots dokumentiert

## Vorschlag fuer den fachlichen Referenzprozess

### Initialisierung

1. Der Benutzer startet den Prozess manuell.
2. Der Benutzer startet den `moodle-cli` Server Mode in Docker oder stellt sicher, dass der Container laeuft.
3. Der Benutzer stellt sicher, dass die benoetigten Konfigurationen vorhanden sind.
   Dazu gehoeren insbesondere:
   - Moodle-Zugang bzw. Session fuer `moodle-cli`
   - Verfuegbarkeit des REST-Endpoints
   - Zugang zur spaeteren LLM-Umgebung
4. Der Benutzer oeffnet ein Terminal fuer den manuellen CLI-Ablauf.
5. Der Benutzer oeffnet einen Browser fuer den LLM-Chat.

### Datenermittlung aus Moodle

6. Der Benutzer ruft mit `moodle-cli` die Kursliste in menschenlesbarer Form ab.
7. Der Benutzer identifiziert den naechsten relevanten Kurs.
8. Der Benutzer ruft mit `moodle-cli` die Dateien oder Ressourcen des ausgewaehlten Kurses ab.
9. Der Benutzer sucht gezielt nach der Semesterinformation oder einer anderen relevanten Kursunterlage.
10. Der Benutzer laesst den Inhalt der relevanten Datei mit `moodle-cli` im Terminal ausgeben.
11. Der Benutzer liest und prueft die ausgegebenen Inhalte.
12. Der Benutzer kopiert die relevanten Inhalte aus dem Terminal.

### LLM-Schritt im Browser

13. Der Benutzer wechselt in den geoeffneten Browser.
14. Der Benutzer oeffnet einen Chat in `ChatGPT` oder `Gemini`.
15. Der Benutzer fuegt den kopierten Moodle-Inhalt in den Chat ein.
16. Der Benutzer fuegt einen Prompt hinzu, um daraus eine strukturierte Ausgabe zu erzeugen.
   Beispielhaft:
   - Lernplan
   - Zusammenfassung
   - To-do-Liste
   - Wochenuebersicht
17. Der Benutzer sendet die Anfrage ab.
18. Der Benutzer wartet auf die Antwort des LLM.
19. Der Benutzer prueft das Resultat fachlich.

### Validierung und Wiederholung

20. Ist das Ergebnis unvollstaendig oder unbrauchbar, passt der Benutzer den Prompt an.
21. Der Benutzer sendet die Anfrage erneut.
22. Dieser Schritt kann mehrfach wiederholt werden, bis ein brauchbares Resultat vorliegt.
23. Wenn das Ergebnis gueltig ist, uebernimmt der Benutzer das Resultat in die gewuenschte Zielstruktur.

### Abschluss

24. Der Benutzer speichert oder uebernimmt das Endergebnis.
25. Der Benutzer wiederholt die Schritte fuer weitere Kurse, falls noetig.
26. Wenn keine weiteren Kurse verarbeitet werden, beendet der Benutzer den Ablauf.

## Mapping auf die bestehende Prozesslogik

Die bisherige grobe Prozesslogik bleibt grundsaetzlich nutzbar, sollte aber inhaltlich so interpretiert werden:

- `Moodle Login`
  Bedeutet im Referenzprozess eher: `moodle-cli` ist korrekt konfiguriert bzw. eine gueltige Session liegt vor.
- `Config und API-Keys laden`
  Bedeutet: Docker-Container, CLI-Konfiguration und spaeterer API-Zugriff sind vorbereitet.
- `Dashboard scannen: Kursliste extrahieren`
  Bedeutet: Kursliste wird ueber `moodle-cli` im Terminal abgefragt.
- `Kurs-Details scrapen`
  Bedeutet: Mensch ruft Kursressourcen ueber CLI auf und waehlt relevante Dateien aus.
- `Semesterinformation PDF suchen`
  Bedeutet: Mensch identifiziert die relevante PDF oder Kursunterlage.
- `Semesterinformation scrapen`
  Bedeutet: CLI gibt den Dateiinhalt aus; Mensch liest ihn im Terminal.
- `Daten an LLM senden`
  Bedeutet im manuellen Referenzprozess: Copy/Paste in Browser-Chat.
- `Validierung`
  Bedeutet: Mensch prueft die Antwort inhaltlich.
- `Invalid & Retry < 3`
  Bedeutet: Prompt anpassen und erneut senden.
- `PDF report generieren`
  Kann spaeter Zielausgabe sein, muss aber fuer den manuellen Referenzprozess nicht zwingend bereits technisch umgesetzt sein.

## Screenshot-Ideen fuer das SDD

Moegliche Screenshots fuer die manuelle Dokumentation:

1. Terminal mit Start des `moodle-cli` bzw. Hinweis auf laufenden Docker-Server
2. Terminal mit menschenlesbarer Ausgabe der Kursliste
3. Terminal mit menschenlesbarer Dateiliste eines Kurses
4. Terminal mit Ausgabe der relevanten Semesterinformation / PDF-Inhalte
5. Browser mit geoeffnetem Chat (`ChatGPT` oder `Gemini`)
6. Browser nach dem Einfuegen der kopierten Inhalte und des Prompts
7. Browser mit generierter LLM-Antwort
8. Optional: manuelle Pruefung oder Uebernahme des Ergebnisses

## Bedeutung fuer die spaetere UiPath-Automatisierung

Der eigentlich zu automatisierende Zielprozess ist dann:

- Start in `UiPath`
- Aufruf der `moodle-cli` REST-API im Docker-Container
- Abruf von Kursen, Dateien und Dateiinhalten ueber HTTP
- Uebergabe der Inhalte an die `Gemini API`
- Empfang und Validierung der Antwort
- Strukturierte Weiterverarbeitung des Ergebnisses

Die manuelle Browser-Variante dient also nur als dokumentierter Referenzprozess fuer die Prozessaufnahme und die Screenshots.

## Offene Punkte

Diese Punkte sollten spaeter im SDD noch explizit entschieden werden:

- Was genau ist die Zieldarstellung des Ergebnisses?
  - Lernplan
  - PDF-Report
  - Markdown
  - Textdatei
- Erfolgt die Verarbeitung pro Kurs oder nur fuer ausgewaehlte Kurse?
- Wie wird ein gueltiges LLM-Ergebnis fachlich definiert?
- Wie viele Retry-Versuche sollen im Soll-Prozess erlaubt sein?
- Soll das Endergebnis gespeichert, versendet oder nur angezeigt werden?

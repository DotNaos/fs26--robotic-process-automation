# Prozessaufzeichnung: Moodle-to-LLM Study Planner

Stand: 2026-05-30

## Zweck

Diese Aufzeichnung dient als Nachweis, dass der komplette RPA-Prozess verstanden, fachlich abgegrenzt und von Anfang bis Ende nachvollziehbar ist.

Die Aufnahme soll nicht nur einzelne Screenshots ersetzen, sondern den gesamten Ablauf zeigen:

1. Start des Prozesses
2. Ermittlung der relevanten Moodle-Informationen
3. Uebergabe an das LLM
4. Pruefung des Ergebnisses
5. Erstellung oder Ablage des Lernplans
6. Abschluss des Prozesses

## Ablage

Die fertige Videodatei wird hier abgelegt:

```text
assets/aufzeichnungen/rpa-prozessdurchlauf-YYYY-MM-DD.mp4
```

Falls die Datei groesser als 100 MB ist, darf sie nicht direkt in GitHub committed werden. In diesem Fall wird sie extern abgelegt und der Link in `assets/aufzeichnungen/README.md` dokumentiert.

## Aufzeichnungsumfang

Die Aufnahme soll den fachlichen Referenzprozess zeigen. Dieser Referenzprozess ist bewusst menschlich sichtbar und entspricht dem Ablauf aus `unterlagen/PROZESS_MANUELLER_ABLAUF.md`.

Der spaetere UiPath-Prozess automatisiert dieselben fachlichen Schritte, nutzt aber APIs und lokale Skripte statt manueller Browser- und Copy/Paste-Schritte.

## Vorbereitung vor der Aufnahme

- Keine Secrets, API Keys, Passwoerter oder Session Tokens sichtbar machen.
- `.env` und andere Konfigurationsdateien mit Geheimnissen geschlossen halten.
- Browser-Tabs mit privaten Inhalten schliessen.
- Terminal so vorbereiten, dass keine vertraulichen alten Befehle sichtbar sind.
- Einen Beispielkurs auswaehlen, dessen Inhalte fuer die Demonstration geeignet sind.
- Ausgabeordner fuer Lernplan, HTML und PDF leeren oder klar erkennbar vorbereiten.
- Aufnahmeprogramm starten und pruefen, dass Bildschirm und Ton korrekt erfasst werden.

## Aufnahmeskript

| Abschnitt | Inhalt der Aufnahme | Nachweis |
| --- | --- | --- |
| 1 | Prozessstart erklaeren und Ausgangslage zeigen | Der Zuschauer erkennt, welcher Prozess demonstriert wird. |
| 2 | Moodle-Quelle oeffnen oder Moodle-Daten ueber CLI/API abrufen | Die Datenquelle ist klar sichtbar. |
| 3 | Kursliste abrufen und relevanten Kurs auswaehlen | Die Kursauswahl ist nachvollziehbar. |
| 4 | Kursressourcen anzeigen und relevante Datei bestimmen | Die benoetigten Eingabedaten sind sichtbar. |
| 5 | Inhalt der relevanten Datei abrufen oder anzeigen | Der Eingabetext fuer das LLM ist nachvollziehbar. |
| 6 | Inhalt und Prompt an das LLM uebergeben | Die Transformation durch das LLM ist sichtbar. |
| 7 | Antwort des LLM pruefen | Es ist erkennbar, dass das Ergebnis fachlich validiert wird. |
| 8 | Bei unbrauchbarem Ergebnis Prompt anpassen und erneut ausfuehren | Der Retry-Fall ist abgedeckt, falls er auftritt. |
| 9 | Gueltiges Ergebnis als Lernplan uebernehmen | Das Zielresultat ist sichtbar. |
| 10 | Markdown, HTML oder PDF erzeugen und Abschluss-Mail vorbereiten oder versenden | Die Zielausgabe ist nachgewiesen. |
| 11 | Prozessende zeigen | Der Durchlauf ist vollstaendig abgeschlossen. |

## Mindestkriterien fuer die Abgabe

Die Aufnahme gilt als brauchbar, wenn alle folgenden Punkte erfuellt sind:

- Der Prozess ist von Start bis Ende in einem zusammenhaengenden Durchlauf sichtbar.
- Die Moodle-Eingaben, LLM-Verarbeitung und Zielausgabe sind nachvollziehbar.
- Es sind keine Passwoerter, API Keys, Tokens oder privaten Inhalte sichtbar.
- Mindestens ein konkreter Kurs wird verarbeitet.
- Das Ergebnis wird sichtbar geprueft.
- Die erzeugte Ausgabe ist am Ende auffindbar.
- Die Aufnahme ist in GitHub dokumentiert oder direkt im Repo abgelegt.

## Nachbearbeitung nach der Aufnahme

Nach dem Aufnehmen werden diese Punkte ergaenzt:

| Feld | Wert |
| --- | --- |
| Dateiname | `<noch offen>` |
| Aufnahmedatum | `<noch offen>` |
| Dauer | `<noch offen>` |
| Verarbeiteter Kurs | `<noch offen>` |
| Ergebnisdatei(en) | `<noch offen>` |
| Ablageort oder Link | `<noch offen>` |

## Zeitindex

Nach der finalen Aufnahme wird hier ein kurzer Zeitindex eingetragen:

| Zeit | Inhalt |
| --- | --- |
| 00:00 | Prozessstart |
|  |  |
|  |  |
|  | Prozessende |

## Bezug zum SDD

Die Aufnahme deckt die Prozessschritte aus Kapitel 5.2 des SDD ab:

| SDD-Schritt | Wird in der Aufnahme gezeigt durch |
| --- | --- |
| Start Taster druecken | Start des manuellen oder UiPath-Durchlaufs |
| Moodle Login | Sichtbarer Zugriff auf Moodle-Daten oder konfigurierte Moodle-CLI/API |
| Config und API-Keys laden | Nur indirekt zeigen, ohne Secrets offenzulegen |
| Dashboard scannen: Kursliste extrahieren | Abruf der Kursliste |
| Kurs-Details scrapen | Abruf der Kursressourcen |
| Semesterinformation PDF suchen | Auswahl der relevanten Datei |
| Semesterinformation scrapen | Auslesen oder Anzeigen des Dateiinhalts |
| Daten an LLM senden | Prompt mit Kursinhalt an das LLM |
| Validierung | Fachliche Pruefung der LLM-Antwort |
| Invalid & Retry | Optionaler zweiter Versuch mit verbessertem Prompt |
| PDF report generieren | Erzeugung der Zielausgabe |
| Abschluss-E-Mail schreiben | Vorbereitung oder Versand der Abschluss-Mail |
| ENDE | Sichtbares Prozessende |


# Prozessaufzeichnungen

Hier liegen die Nachweise fuer den vollstaendigen Prozessdurchlauf.

## Sichtbare Prozess- und Datenaufnahme

```text
rpa-visible-process-data-run-2026-05-31.mp4
```

Status: erstellt, komprimiert und per Stichprobenframes geprueft.

```text
Datum: 2026-05-31
Dauer: 02:45
Gezeigter Kurs: 22576 / RPA
Aufloesung: 1920x1206
Dateigroesse: ca. 3.3 MB
```

Diese Aufnahme wurde direkt auf dem Windows-Yoga aufgezeichnet. Sie zeigt nicht nur ein Terminal, sondern die Zwischendaten des Prozesses:

- Moodle-API-Healthcheck
- FS26-Kursliste und ausgewaehlter RPA-Kurs
- Zurueckgegebene Moodle-Ressourcen
- Textauszug aus der ausgewaehlten Moodle-Ressource
- Gemini/LLM-Antwort
- gespeicherter Markdown-Output

Keine Passwoerter, API Keys oder Tokens sind sichtbar.

## Echte UiPath-Prozessaufnahme

```text
rpa-uipath-robot-real-run-2026-05-30.mp4
```

Status: erstellt und geprueft.

```text
Datum: 2026-05-30
Dauer: 03:00
Gezeigter Kurs: 22576 / RPA
Aufloesung: 1280x804
```

Die Aufnahme zeigt den realen UiPath-Roboterdurchlauf auf dem Windows-System. Sie bleibt als technischer Nachweis fuer den Robot-Lauf relevant; fuer die inhaltlich besser sichtbaren Zwischendaten ist die neue Aufnahme vom 2026-05-31 besser geeignet.

- UiPath-Projekt und Paketvorbereitung
- Docker/Moodle-API-Pruefung ueber `/healthz`
- Vorbereitung der Recording-Umgebung ohne sichtbare Secrets
- Start des UiPath-Roboters ueber `UiRobot execute`
- Moodle-Datenabruf, Gemini-Schritt und Ergebnisdatei
- Abschluss mit `Robot Exit Code: 0`
- Vorschau des erzeugten Markdown-Lernplans

## Zusaetzliches Walkthrough-Video

Eine secret-freie Walkthrough-Aufzeichnung aus den echten Nachweisbildern liegt zusaetzlich vor:

```text
rpa-prozessdurchlauf-walkthrough-2026-05-30.mp4
```

Diese Datei zeigt Architektur, Windows-Laufnachweis, generierten HTML-Lernplan und Moodle-Quellen. Sie ist nur noch als kompakter Zusatznachweis fuer Bericht und Praesentation gedacht.

## Screenshot-Nachweise fuer Bericht und Praesentation

Die folgenden Bilder koennen direkt in die schriftliche Arbeit und in die Schlusspräsentation übernommen werden:

| Datei | Zweck |
| --- | --- |
| `automation-architecture-2026-05-30.png` | Zielarchitektur der UiPath-Automatisierung |
| `run-evidence-terminal-2026-05-30.png` | Nachweis des Windows-Laufs ohne sichtbare Secrets |
| `lernplan-output-2026-05-30.png` | Screenshot des generierten HTML-Lernplans |
| `moodle-sources-2026-05-30.png` | Screenshot der ausgewerteten Moodle-Quellen |

Die Screenshots ergaenzen die echte Prozessaufnahme und koennen fuer Bericht und Schlussprasentation verwendet werden.

## Vor dem Hochladen pruefen

- Keine Passwoerter sichtbar
- Keine API Keys sichtbar
- Keine privaten Inhalte sichtbar
- Prozessstart, Moodle-Daten, LLM-Schritt, Ergebnispruefung und Abschluss sichtbar
- Datei laesst sich abspielen

# Screenshot-Auswahl fuer Bericht und Schlusspräsentation

Stand: 2026-05-31

## Empfohlene Einbindung

| Abschnitt | Video | Aussage |
| --- | --- | --- |
| Prozessdurchlauf / Datenfluss | `../assets/aufzeichnungen/rpa-visible-process-data-email-pdf-run-2026-05-31.mp4` | Die Aufnahme zeigt den Prozess sichtbar auf dem Yoga: Moodle-API, Kursauswahl, Ressourcen, Textauszug, LLM-Antwort, PDF-Rendering, E-Mail-Schritt und das fertige PDF. |
| Technischer Robot-Nachweis | `../assets/aufzeichnungen/rpa-uipath-robot-real-run-2026-05-30.mp4` | Der echte UiPath-Roboterlauf wurde auf Windows aufgezeichnet und endet mit `Robot Exit Code: 0`. |

| Abschnitt | Screenshot | Aussage |
| --- | --- | --- |
| Prozessbeschreibung / Architektur | `../assets/aufzeichnungen/automation-architecture-2026-05-30.png` | UiPath orchestriert Moodle API, LLM, Rendering und optionalen Mailversand. |
| Beschreibung der Automatisierung | `../assets/aufzeichnungen/run-evidence-terminal-2026-05-30.png` | Der Windows-Lauf erzeugt Output, ohne Secrets sichtbar zu machen. |
| Ergebnis / Testing | `../assets/aufzeichnungen/lernplan-output-2026-05-30.png` | Der generierte HTML-Lernplan ist als Zielartefakt nachvollziehbar. |
| Quellen und Nachvollziehbarkeit | `../assets/aufzeichnungen/moodle-sources-2026-05-30.png` | Die ausgewerteten Moodle-Dateien werden als Quellen-JSON mitgeführt. |

## Zusaetzlicher Nachweis

Ein secret-freies Walkthrough-Video liegt unter `../assets/aufzeichnungen/rpa-prozessdurchlauf-walkthrough-2026-05-30.mp4`.

Dieses Walkthrough-Video bleibt als kompakte Ergaenzung nuetzlich. Fuer die Abgabe ist die wichtigste Prozessaufnahme jetzt `../assets/aufzeichnungen/rpa-visible-process-data-email-pdf-run-2026-05-31.mp4`, weil dort die zurueckkommenden Daten, der LLM-Schritt, der E-Mail-Schritt und das finale PDF sichtbar sind.

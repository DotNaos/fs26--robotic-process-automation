# Moodle Notizen

Stand: 2026-04-12

## Quelle

Die Informationen in dieser Datei wurden direkt aus FHGR Moodle gelesen:

- ueber die Aufgabenansicht in Moodle
- ueber die Kursansicht
- ueber `moodle-cli` fuer Kurs- und Dateilisten

## Relevanter Kurs

- Kursname: `Hyperautomation und Robotics Process Automation (RPA) / Process Automation & Mining (cds-309/dsc_23/dsc_22/dbmWPM)`
- Kurs-ID: `22576`
- Semester: `FS26`

## Arbeitsauftrag

- Titel: `Arbeitsauftrag Prozessqualifizierung (Leistungskontrolle 20%)`
- Geoeffnet: `Freitag, 13. Februar 2026, 00:00`
- Faellig: `Donnerstag, 16. April 2026, 00:00`
- Moodle-Aufgaben-ID / View-Link: `mod/assign/view.php?id=937043`

### Exakter Inhalt aus Moodle

In dieser Gruppenarbeit ist ein selbst definierter Prozess welcher mittels RPA automatisiert werden soll zu dokumentieren und qualifizieren.

Arbeitsauftrag (Leistungskontrolle 20%) bis 16.04.2026

Waehlt einen angemessenen Prozess aus. Der gewaehlte Prozess sollte aus ca. 15-30 Prozessschritten bestehen und gut mit einem RPA-Tool automatisiert werden koennen.

Am meisten lernt ihr, wenn ihr einen Bezug zu einer Organisation herstellt und bei dieser Organisation einen (Teil-)Prozess automatisiert.

Beschreibt den ausgewaehlten Prozess mittels einer Flowchart-Darstellung. Das Ziel ist transparent darzustellen, wie der Prozess funktioniert.

Nutzt dabei die Dokumente PQD/SDD aus dem Kurs.

Verwendet Materialien und Vorgehensweisen aus dem Kurs um den Prozess zu qualifizieren:

- Inwiefern ist der Prozess fuer die Automatisierung geeignet?
- Inwiefern ist es oekonomisch sinnvoll, den Prozess zu automatisieren (Business Case / ROI)?

## Aktueller Abgabestatus in Moodle

- Status: `Bisher wurden keine Aufgaben abgegeben`
- Bewertungsstatus: `Nicht bewertet`

## Anhaenge an der Aufgabe

- `BEISPIEL_KSGR - UC40 Mahnungen Kostentraeger - RPA SDD - V1.0.pdf`
- `FHGR - UCXX (Process Name) - RPA SDD.docx`
- `FHGR_PQD_Template.pptx`

### Einordnung der Anhaenge

- Das `KSGR`-PDF ist ein ausgefuelltes Beispiel-SDD aus einem anderen Use Case.
- Das `FHGR - UCXX`-DOCX ist eine SDD-Vorlage.
- Das `FHGR_PQD_Template`-PPTX ist eine PQD-Vorlage.
- Der eigentliche Arbeitsauftrag steht in der Moodle-Aufgabenbeschreibung, nicht in diesen drei Dateien.

## Woche-1-Unterlagen im Kurs

Dateiliste aus dem Kurs:

- `Unterlagen Tag 1 (12.02.2026)` - Resource-ID `947197`
- `Unterlagen Tag 2 (13.02.2026)` - Resource-ID `947671`

## Erkenntnisse aus den Vorlesungsfolien

### Tag 1 - Einfuehrung RPA

Wichtige Punkte:

- Warum RPA gebraucht wird: Fachkraeftemangel, Kostendruck, Digitalisierung, regulatorische Anforderungen.
- RPA eignet sich vor allem fuer Prozesse mit digitalem Input, klaren Regeln, Wiederholungen, Volumen und strukturierteren Daten.
- Zentrale Nutzenargumente:
  - schnellere Ausfuehrung
  - weniger Fehler
  - bessere Compliance
  - tiefere Kosten
  - Skalierbarkeit
  - schneller ROI
- Unterscheidung `Attended` vs. `Unattended` Automation.
- Einordnung von `RPA`, `Intelligent Automation`, `Hyperautomation` und `Agentic Automation`.
- Hyperautomation ist breiter als klassisches RPA und kombiniert mehrere Technologien.

### Tag 2 - Prozessidentifikation und Qualifizierung

Wichtige Punkte:

- Moegliche Wege zur Prozessidentifikation:
  - Workshops
  - Interviews
  - Shadowing
  - Ideenplattformen wie Automation Hub
- Dokumentationswerkzeuge:
  - `PQD` fuer die Qualifizierung eines Prozesses
  - `SDD` fuer die Soll-Dokumentation zur Umsetzung
- BPMN und Flowcharts sind wichtige Modellierungswerkzeuge.
- Wirtschaftlichkeit / ROI wird u.a. ueber folgende Groessen betrachtet:
  - Prozesshaeufigkeit
  - Bearbeitungsdauer
  - Fehlerrate
  - Fehlerbehebungsaufwand
  - Vollkosten
  - weitere Nutzenpunkte wie Kundenzufriedenheit, Mitarbeiterzufriedenheit, Compliance
- Best Practice:
  - schlechte Prozesse zuerst optimieren, dann automatisieren
  - Teilprozesse duerfen ebenfalls automatisiert werden
  - ein Prozess muss nicht zwingend vollstaendig end-to-end automatisiert sein

## Relevanz fuer dieses Projekt

Der aktuelle Projektansatz `Moodle-to-LLM Study Planner` passt grundsaetzlich gut zu den Kursinhalten:

- digitaler Input aus Moodle
- wiederkehrender Ablauf
- in Teilbereichen regelbasiert
- fachlich nachvollziehbarer Organisationsbezug: Studium / Lernmanagement

Wichtige Punkte fuer die Abgabe:

- Prozess soll ca. `15-30 Schritte` haben
- Prozess soll als `Flowchart` dokumentiert werden
- `PQD/SDD` sollen verwendet werden
- Automatisierbarkeit und Wirtschaftlichkeit sollen begruendet werden
- Teilautomatisierung ist akzeptabel, wenn sie sinnvoll begruendet ist

## Moodle-CLI Erkenntnisse

In dieser Session wurde `moodle-cli` erfolgreich fuer folgende Aufgaben verwendet:

- Kursliste lesen
- Dateiliste eines Kurses lesen

Wichtige Beobachtungen:

- Eine gueltige Moodle-Session ist notwendig.
- `list courses` und `list files` funktionierten mit einer gueltigen Session.
- Die aktuelle Build zeigte in dieser Session Probleme bei `print` und `download file`: statt der Dateioperation kam ein Fehler zu `calendar URL not set`.
- Deshalb wurden einige Inhalte alternativ direkt ueber die gueltige Moodle-Session gelesen.

## Bereits bekannte lokale Projektdateien

- SDD in Word: `/home/oli/projects/rpa/unterlagen/FHGR - UCXX (Moodle Scraping) - RPA SDD.docx`
- Markdown-Transfer des SDD:
  `/home/oli/projects/rpa/unterlagen/FHGR - UCXX (Moodle Scraping) - RPA SDD.md`

## Zweck dieser Datei

Diese Datei dient als persistente Arbeitsnotiz, damit Moodle-Erkenntnisse nicht erneut beschafft werden muessen.

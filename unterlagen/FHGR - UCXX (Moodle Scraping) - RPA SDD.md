# RPA Solution Design Document

## Moodle Lernplan

## Versionshistorie

| Version | Hauptautor(en) | Beschreibung der Version | Datum |
| --- | --- | --- | --- |
| 0.1 | Florin Gartmann | Initiale Version | 07.04.2026 |
| 0.2 | Michal Karczmarzyk | Grobe Prozessbeschreibung | 12.04.2026 |
| 0.3 | Oliver Schütz | Screenshots Prozessschritte | 12.04.2026 |

## Verantwortlichkeiten

| Rolle | Name |
| --- | --- |
| Projektleiter | Florin Gartmann |
| Prozessverantwortlicher | Oliver Schütz |
| Teamleiter | Alessio De Icco |
| Sachbearbeiter | Alessio De Icco |
| RPA Entwickler | Michal Karczmarzyk |
| RPA Business Analyst | Florin Gartmann |

## Dokumentenbewilligung

| Name | Projektrolle | Datum der Überprüfung |
| --- | --- | --- |
| Florin Gartmann | Projektleiter |  |
| Oliver Schütz | Prozessverantwortlicher |  |
| Alessio De Icco | Teamleiter |  |
| Michal Karczmarzyk | RPA-Entwickler |  |

## Inhaltsverzeichnis

1. Ziel des Dokumentes
2. Prozessinformationen und -kennzahlen
3. Prozessauslöser
4. Kernanwendungen
5. Prozessbeschreibung und -design
6. Testing
7. Appendix

## 1. Ziel des Dokumentes

Das Solution Design Dokument (SDD) beschreibt die funktionalen und nicht-funktionalen Anforderungen sowie alle weiteren Informationen, die eine vollständige Spezifikation eines zu automatisierenden Prozesses ermöglichen. Dieses Dokument fungiert insbesondere als Vereinbarung zwischen folgenden Parteien:

- Prozessverantwortliche:r
- Teamleiter:in
- Sachbearbeiter:in
- Business Analyst:in
- RPA-Entwickler:in

Sämtliche Prozessschritte, welche in diesem Dokument nicht aufgeführt sind, sind Out-Of-Scope. Änderungen, welche nach Bewilligung dieses Dokuments am unterliegenden Prozess erfolgen, lösen automatisch einen Change Request aus.

## 2. Prozessinformationen und -kennzahlen

| Prozessinformation | Angabe |
| --- | --- |
| Prozesslevel 0 | IT-Services Studium |
| Prozesslevel 1 | Lernmanagement |
| Prozesslevel 2 | Informationsbeschaffung |
| Prozesslevel 3 | Kurs-Scraping & Lernplanerstellung |
| Prozessname | Moodle-to-LLM Study Planner |

| Prozesskennzahl | Angabe |
| --- | --- |
| Frequenz | Wöchentlich |
| Zeitpunkt | Beliebig |
| Prozessdauer (Ø pro Fall) | 15 min. / Fall |
| Prozessvolumen | 10 Fälle / Woche |
| Maximales Volumen | 20 Fälle / Woche |
| SLA pro Fall | Sofort |
| Anzahl automatisierbare Prozessstunden | 10 Stück * 15 Min. * 14 Wochen = 35h/Semester |

## Business Case / Wirtschaftlichkeit

Die Automatisierung ist wirtschaftlich sinnvoll, wenn sie nicht als einmaliger Studenten-Shortcut, sondern als wiederholbarer Lernmanagement-Prozess betrachtet wird. Die Rechnung ist bewusst konservativ und basiert auf den bereits dokumentierten Prozesskennzahlen.

| Annahme | Wert | Herleitung | Bedeutung |
| --- | --- | --- | --- |
| Volumen | 140 Fälle / Semester | 10 Fälle pro Woche * 14 Wochen | typischer FS26-Betrachtungshorizont |
| Manueller Aufwand | 35.0 Stunden | 140 Fälle * 15 Minuten | Suchen, Kopieren, Prompten und Prüfen ohne Bot |
| Restaufwand nach Automatisierung | 4.7 Stunden | 140 Fälle * 2 Minuten Kontrolle | Starten, Ergebnis prüfen, Ausnahmefälle behandeln |
| Netto-Zeitersparnis | 30.3 Stunden / Semester | 35.0h - 4.7h | realistischer Zeitgewinn nach menschlicher Prüfung |
| Interner Stundensatz | CHF 40 / Stunde | konservative Annahme für studentische/administrative Bearbeitung | Basis für den monetären Vergleich |

**Monetäre Wirkung:** Der manuelle Semesteraufwand entspricht ca. CHF 1'400. Nach Automatisierung verbleiben ca. CHF 187 Kontrollaufwand. Daraus ergibt sich eine erwartete Ersparnis von ca. CHF 1'213 pro Semester.

**Kosten der Umsetzung:** Für die einmalige Entwicklung und Dokumentation wird konservativ mit ca. 35 Stunden gerechnet, also ca. CHF 1'400 bei CHF 40/h. Zusätzliche Toolkosten sind gering: UiPath Community/Studio im Ausbildungskontext, Docker lokal, Moodle API lokal und Gemini API im erwarteten Nutzungsumfang im einstelligen CHF-Bereich pro Semester. Laufende Wartung wird mit ca. 2 Stunden pro Semester angesetzt.

**ROI-Einschätzung:** Bei nur einem einzelnen Studentenprozess amortisiert sich der Aufbau ungefähr nach 1.2 Semestern. Wird der Prozess für mehrere Studierende, mehrere Kurse oder wiederkehrende Studiengänge verwendet, sinkt die Amortisationszeit deutlich. Der qualitative Nutzen besteht zusätzlich in weniger Copy/Paste-Fehlern, reproduzierbarer Quellenlage und besser nachvollziehbaren Lernplan-Ergebnissen.

## 3. Prozessauslöser

### 3.1 Aktueller Prozessauslöser

Dokumente und Termine müssen händisch von Moodle heruntergeladen, kopiert und manuell in ein LLM (z.B. ChatGPT) übertragen werden, um einen strukturierten Lernplan zu erhalten.

### 3.2 Zukünftiger Prozessauslöser

Der Prozess wird manuell durch den Klick auf eine Taste (User Trigger) in UiPath gestartet. Ein zeitgesteuerter Trigger ist weniger sinnvoll, da das Bedürfnis nach einem Lernplan meist direkt nach Kursaktualisierungen besteht.

## 4. Kernanwendungen

| Anwendungsname | Umgebung | Beschreibung/Zugriff |
| --- | --- | --- |
| Moodle CLI / API (FHGR) | API / Kommandozeile | Primäre Datenquelle für Kursinhalte und Deadlines. |
| Gemini (Gemini API) | API | LLM zur Verarbeitung der Rohdaten und Erstellung des Lernplans. |
| UiPath Studio | Desktop | Entwicklungsumgebung und Execution Engine. |
| JSON/Text File | Lokal | Zwischenspeicherung der extrahierten Kursdaten. |

### 4.1 Bekannte, für diesen Prozess relevante Releasewechsel

| Anwendungsname & Version | Release Version | Release Datum | Kommentar |
| --- | --- | --- | --- |
| Keine |  |  |  |

## 5. Prozessbeschreibung und -design

### 5.1 Prozessübersicht

### 5.2 Prozessschritte

In der nachfolgenden Prozessbeschreibung gelten folgende Begrifflichkeiten:

- `[Button]` = Beschreibung eines anzuwählenden Symbols in einer Applikation (z.B. `[Datei]`)
- `[Exception:]` = Beschreibung eines möglichen Ausnahmefalles, welcher im Kapitel 5.3 spezifiziert wird (z.B. `[Exception 1]`
- `{Variable}` = Beschreibung eines variablen Wertes, welcher der Roboter sich merken soll (z.B. `{30.11.2019}`)
- `{Config: Variable}` = Beschreibt einen variablen Wert, welcher ausserhalb des Bot-Codes gespeichert werden soll (z.B. `{String: 18:00:00}`

| Schritt | Beschreibung | Screenshot |
| --- | --- | --- |
| 1 | **Start Taster drücken**. Der Benutzer startet den Bot-Prozess manuell. | `(nur 1 Screenshot pro Schritt!)` `(C4-Daten vor dem Einfügen entfernen)` `(Breite des Screenshots auf maximal 15cm reduzieren)` |
| 2 | **Moodle Login**. Der Bot meldet sich mit den hinterlegten Zugangsdaten in Moodle an. |  |
| 3 | **Config und API-Keys laden**. Der Bot lädt die benötigte Konfiguration und die API-Keys. |  |
| 4 | **Dashboard scannen: Kursliste extrahieren**. Der Bot scannt das Dashboard und erstellt die Liste aller zu verarbeitende Kurse. |  |
| 5 | **Nächster Kurs?** Der Bot prüft, ob ein weiterer Kurs vorhanden ist. |  |
| 6 | **JA: Kurs-Details scrapen**. Für den nächsten Kurs werden die relevanten Kursdetails ausgelesen. |  |
| 7 | **Semesterinformation PDF suchen**. Der Bot sucht im Kurs nach der Semesterinformations-PDF. |  |
| 8 | **Semesterinformation scrapen**. Die Inhalte der Semesterinformation werden extrahiert. |  |
| 9 | **Daten an LLM senden**. Die extrahierten Daten werden zur Verarbeitung an das LLM übergeben. |  |
| 10 | **Validierung**. Das Ergebnis des LLM wird auf Gültigkeit geprüft. |  |
| 11 | **Invalid & Retry < 3**. Ist das Ergebnis ungültig und die Anzahl der Versuche kleiner als 3, werden die Daten erneut an das LLM gesendet. |  |
| 12 | **Invalid & Retry >= 3**. Ist das Ergebnis nach dem dritten Versuch weiterhin ungültig, wird ein Fehler ausgegeben. |  |
| 13 | **Valid**. Bei gültigem Ergebnis wird ein PDF-Report generiert. |  |
| 14 | **Rücksprung zur Kursprüfung**. Nach Report-Generierung oder Fehler-Logging springt der Prozess zurück zu Nächster Kurs. |  |
| 15 | **NEIN: Abschluss-E-Mail schreiben**. Wenn keine weiteren Kurse vorhanden sind, wird die Abschluss-E-Mail erstellt und versendet. |  |
| 16 | **ENDE**. Der Prozess wird beendet. |  |

### 5.3 Exception Handling (Fehler, Ausnahmen und Pop up's)

| Nummer | Beschreibung | Screenshot |
| --- | --- | --- |
| [Exception 1] | Beispiel für eine Bot-Exception. Versende das E-Mail auf der rechten Seite. Verschiebe das aktuell bearbeitete `.xls` File nach `/03 - Exceptions/`. Lösche alle Variablen aus dem Zwischenspeicher. Beende den Durchlauf. | **Empfänger:** `[Mailbox]` **Titel:** `<Kunde> – <UC-ID> <Prozessname>: Exception 1 erkannt` **Text:** `*** Automatische Nachricht ***` **Betroffener Auftrag** Auftrag: `{Auftrag}` Kontonummer: `{Kontonummer}` **Exception 1** `{Exception 1 Text}` **Nächste Schritte** Der Auftrag wurde in den Ordner `"/03 – Exceptions"` verschoben. Bitte korrigieren Sie den Auftrag und übergeben Sie in erneut an der Roboter oder führen Sie den Auftrag manuell aus. Vielen Dank. **Support** Sollte ein technisches Problem mit dem Roboter vorliegen, so wenden Sie sich bitte an…. |

## 6. Testing

Dieser Abschnitt beschreibt die Kriterien, anhand welcher der Roboter nach Fertigstellung der Entwicklung getestet wird. Sollte der Roboter sämtliche Testfälle bestehen, gilt die Entwicklung als abgeschlossen. Sollten zusätzliche Elemente getestet und entwickelt werden müssen, so ist dies im Rahmen eines Change Requests zu beantragen.

### 6.1 Testfälle und Testdaten

| Testfall | Beschreibung |
| --- | --- |
| 1.0 |  |
| 2.0 |  |
| 2.1 |  |
| 2.2 |  |

### 6.2 Generierung von Testfällen

| Schritt | Beschreibung | Screenshot |
| --- | --- | --- |
| 1 |  |  |
| 2 |  |  |
| 3 |  |  |
| 4 |  |  |

## 7. Appendix

### 7.1 Speicherung der Login Daten

Die Logindaten, welche für die Applikationen und Systeme verwendet werden, werden lokal in `.env` beziehungsweise in UiPath-Konfigurationen gespeichert. Secrets, API Keys und Passwörter werden nicht in Git versioniert und in Nachweisvideos nicht sichtbar gemacht.

### 7.2 Risiken, Issues und Abhängigkeiten

| Beschreibung | Aktion | Verantwortlichkeit | Zu erledigen bis |
| --- | --- | --- | --- |
| R: Know-How-Verlust | Sicherstellung des Know-Hows durch eine geeignete Massnahme | Prozessverantwortlicher | Vor Go-Live |
| R: Evaluation von Betrugsrisiken im Prozess | Der Business Analyst beurteilt das Betrugsrisiko gemeinsam mit dem Prozessverantwortlichen. Gemeinsam definieren sie die Sicherungs-massnahmen und dokumentieren diese in der Prozessbeschreibung. | Business Analyst / Prozessverantwortlicher | Vor Entwicklungs-start |

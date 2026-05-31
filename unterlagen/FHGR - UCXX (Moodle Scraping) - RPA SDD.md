# RPA Solution Design Document

## Moodle Lernplan

## Versionshistorie

| Version | Hauptautor(en) | Beschreibung der Version | Datum |
| --- | --- | --- | --- |
| 0.1 | Florin Gartmann | Initiale Version | 07.04.2026 |
| 0.2 | Michal Karczmarzyk | Grobe Prozessbeschreibung | 12.04.2026 |
| 0.3 | Oliver Schütz | Screenshots Prozessschritte | 12.04.2026 |
| 0.4 | Oliver Schütz | Bericht vervollständigt: Business Case, Prozessübersicht, Reflexion, Ausblick | 31.05.2026 |

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
2. Management Summary
3. Prozessinformationen und -kennzahlen
4. Business Case / Wirtschaftlichkeit
5. Prozessauslöser
   5.1 Aktueller Prozessauslöser
   5.2 Zukünftiger Prozessauslöser
6. Kernanwendungen
7. Prozessbeschreibung und -design
   7.1 Prozessübersicht
   7.2 Prozessschritte
   7.3 Exception Handling (Fehler, Ausnahmen und Pop up's)
8. Herausforderungen, Chancen und AI-Ausblick
9. Testing
10. Reflexion und Arbeitsaufteilung
11. Appendix

## 1. Ziel des Dokumentes

Das Solution Design Dokument (SDD) beschreibt die funktionalen und nicht-funktionalen Anforderungen sowie alle weiteren Informationen, die eine vollständige Spezifikation eines zu automatisierenden Prozesses ermöglichen. Dieses Dokument fungiert insbesondere als Vereinbarung zwischen folgenden Parteien:

- Prozessverantwortliche:r
- Teamleiter:in
- Sachbearbeiter:in
- Business Analyst:in
- RPA-Entwickler:in

Sämtliche Prozessschritte, welche in diesem Dokument nicht aufgeführt sind, sind Out-Of-Scope. Änderungen, welche nach Bewilligung dieses Dokuments am unterliegenden Prozess erfolgen, lösen automatisch einen Change Request aus.

## 2. Management Summary

Der Moodle-to-LLM Study Planner automatisiert einen wiederkehrenden Studienprozess: Moodle-Kurse und Kursressourcen werden ausgelesen, relevante Inhalte werden an ein LLM übergeben, daraus wird ein strukturierter Lernplan erzeugt und am Ende als PDF beziehungsweise E-Mail-Ergebnis bereitgestellt.

Der Prozess eignet sich für RPA, weil die Eingabedaten digital vorliegen, der Ablauf wiederkehrend ist und die Entscheidungspunkte klar beschrieben werden können. Die Lösung ist bewusst als Attended Automation gestaltet: Der Roboter übernimmt Sammlung, Strukturierung und Ausgabe, während der Mensch das Ergebnis fachlich prüft.

Wirtschaftlich ergibt sich bei 140 Fällen pro Semester ein manueller Aufwand von ca. 35 Stunden. Nach Automatisierung verbleiben ca. 4.7 Stunden Kontrollaufwand. Bei einem konservativen internen Satz von CHF 40/h entspricht dies einer Ersparnis von rund CHF 1'213 pro Semester.

## 3. Prozessinformationen und -kennzahlen

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

## 4. Business Case / Wirtschaftlichkeit

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

## 5. Prozessauslöser

### 5.1 Aktueller Prozessauslöser

Dokumente und Termine müssen händisch von Moodle heruntergeladen, kopiert und manuell in ein LLM (z.B. ChatGPT) übertragen werden, um einen strukturierten Lernplan zu erhalten.

### 5.2 Zukünftiger Prozessauslöser

Der Prozess wird manuell durch den Klick auf eine Taste (User Trigger) in UiPath gestartet. Ein zeitgesteuerter Trigger ist weniger sinnvoll, da das Bedürfnis nach einem Lernplan meist direkt nach Kursaktualisierungen besteht.

## 6. Kernanwendungen

| Anwendungsname | Umgebung | Beschreibung/Zugriff |
| --- | --- | --- |
| Moodle CLI / API (FHGR) | API / Kommandozeile | Primäre Datenquelle für Kursinhalte und Deadlines. |
| Gemini (Gemini API) | API | LLM zur Verarbeitung der Rohdaten und Erstellung des Lernplans. |
| UiPath Studio | Desktop | Entwicklungsumgebung und Execution Engine. |
| JSON/Text File | Lokal | Zwischenspeicherung der extrahierten Kursdaten. |

### 6.1 Bekannte, für diesen Prozess relevante Releasewechsel

| Anwendungsname & Version | Release Version | Release Datum | Kommentar |
| --- | --- | --- | --- |
| Keine |  |  |  |

## 7. Prozessbeschreibung und -design

### 7.1 Prozessübersicht

Der Zielprozess wird als kontrollierter Attended-RPA-Ablauf umgesetzt. Der Benutzer startet den Roboter, der Roboter liest Konfiguration und Moodle-Daten, erstellt mit Gemini den Lernplan, rendert das Ergebnis als PDF und verschickt beziehungsweise zeigt das Ergebnis am Ende zur Prüfung an.

| Flowchart-Element | Schritt | Output / Entscheidung |
| --- | --- | --- |
| Start | Benutzer startet den UiPath-Prozess | Prozesslauf wird initialisiert |
| Prozess | Konfiguration und Credentials laden | `.env` / UiPath-Konfiguration ist verfügbar |
| Entscheidung | Moodle API erreichbar? | Nein: Fehler melden; Ja: weiter |
| Prozess | Kursliste aus Moodle abrufen | Liste relevanter Kurse |
| Entscheidung | Nächster Kurs vorhanden? | Nein: Abschluss-E-Mail; Ja: Kurs bearbeiten |
| Prozess | Kursressourcen und Termine abrufen | Rohdaten pro Kurs |
| Entscheidung | Relevante Quelle gefunden? | Nein: Hinweis protokollieren; Ja: LLM vorbereiten |
| Prozess | Daten an Gemini senden | Strukturierter Lernplan-Entwurf |
| Entscheidung | Antwort valide? | Nein: Retry bis maximal 3 Versuche; Ja: weiter |
| Prozess | Lernplan als PDF rendern | Finale PDF-Datei |
| Prozess | E-Mail mit Ergebnis erstellen | Versand oder Entwurf mit PDF-Hinweis |
| Ende | Ergebnis prüfen | Menschliche Endkontrolle |

### 7.2 Prozessschritte

In der nachfolgenden Prozessbeschreibung gelten folgende Begrifflichkeiten:

- `[Button]` = Beschreibung eines anzuwählenden Symbols in einer Applikation (z.B. `[Datei]`)
- `[Exception:]` = Beschreibung eines möglichen Ausnahmefalles, welcher im Kapitel 5.3 spezifiziert wird (z.B. `[Exception 1]`
- `{Variable}` = Beschreibung eines variablen Wertes, welcher der Roboter sich merken soll (z.B. `{30.11.2019}`)
- `{Config: Variable}` = Beschreibt einen variablen Wert, welcher ausserhalb des Bot-Codes gespeichert werden soll (z.B. `{String: 18:00:00}`

| Schritt | Beschreibung | Screenshot |
| --- | --- | --- |
| 1 | **Start Taster drücken**. Der Benutzer startet den Bot-Prozess manuell. |  |
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

### 7.3 Exception Handling (Fehler, Ausnahmen und Pop up's)

| Nummer | Beschreibung | Screenshot |
| --- | --- | --- |
| [Exception 1] | Beispiel für eine Bot-Exception. Versende das E-Mail auf der rechten Seite. Verschiebe das aktuell bearbeitete `.xls` File nach `/03 - Exceptions/`. Lösche alle Variablen aus dem Zwischenspeicher. Beende den Durchlauf. | **Empfänger:** `[Mailbox]` **Titel:** `<Kunde> – <UC-ID> <Prozessname>: Exception 1 erkannt` **Text:** `*** Automatische Nachricht ***` **Betroffener Auftrag** Auftrag: `{Auftrag}` Kontonummer: `{Kontonummer}` **Exception 1** `{Exception 1 Text}` **Nächste Schritte** Der Auftrag wurde in den Ordner `"/03 – Exceptions"` verschoben. Bitte korrigieren Sie den Auftrag und übergeben Sie in erneut an der Roboter oder führen Sie den Auftrag manuell aus. Vielen Dank. **Support** Sollte ein technisches Problem mit dem Roboter vorliegen, so wenden Sie sich bitte an. |

## 8. Herausforderungen, Chancen und AI-Ausblick

### 8.1 Herausforderungen

Die wichtigste Herausforderung ist die Stabilität der Schnittstellen. Moodle-Inhalte können unterschiedlich strukturiert sein, Ressourcen können fehlen oder anders benannt sein, und API-Antworten müssen deshalb robust validiert werden. Zusätzlich muss der LLM-Output geprüft werden, weil ein sprachliches Modell zwar gut strukturiert, aber nicht automatisch fachlich korrekt ist.

Eine zweite Herausforderung ist der Nachweis des Prozesses. Für die Bewertung muss sichtbar sein, was der Roboter tut und welche Daten zurückkommen, ohne dabei Zugangsdaten oder API-Keys offenzulegen. Deshalb werden Credentials lokal gespeichert und Nachweise so erstellt, dass Zwischenergebnisse sichtbar, aber Secrets verborgen bleiben.

### 8.2 Chancen

Die Automatisierung reduziert manuelle Copy/Paste-Arbeit und damit Übertragungsfehler. Gleichzeitig entsteht eine reproduzierbare Datenbasis: Der Lernplan kann auf Moodle-Ressourcen, Deadlines und Kursinformationen zurückgeführt werden. Die Lösung lässt sich ausserdem auf mehrere Kurse und wiederkehrende Semester übertragen.

### 8.3 Verbesserung durch Analytics, Machine Learning und AI

Analytics könnte künftig messen, welche Moodle-Ressourcen besonders häufig in Lernplänen verwendet werden, wo Informationen fehlen und bei welchen Kursen die meisten Nacharbeiten entstehen. Daraus könnten Warnungen für unvollständige Kursräume oder schlecht strukturierte Materialien entstehen.

Machine Learning könnte Ressourcen automatisch klassifizieren, zum Beispiel Semesterinformation, Prüfungsangaben, Übungen, Folien oder allgemeine Zusatzmaterialien. Dadurch müsste der Roboter weniger über Dateinamen entscheiden.

Generative AI ist bereits Teil der Lösung, weil Gemini aus den extrahierten Rohdaten einen Lernplan formuliert. Der nächste sinnvolle Schritt wäre eine strengere Validierung: Das Modell müsste seine Aussagen mit Moodle-Quellen begründen, fehlende Informationen markieren und unsichere Annahmen explizit ausweisen.

### 8.4 Ausblick

Kurzfristig kann die Lösung mehrere Kurse in einem Lauf verarbeiten und die Ergebnisse in einer einheitlichen Übersicht zusammenfassen. Mittelfristig wäre eine Kalenderintegration sinnvoll, damit Deadlines und Lernblöcke direkt in einen persönlichen Studienkalender übernommen werden können. Langfristig könnte der Prozess als wiederverwendbarer Hochschul-Assistent dienen, der Kursinformationen sammelt, strukturiert, validiert und nur noch zur Endfreigabe an den Menschen übergibt.

## 9. Testing

Dieser Abschnitt beschreibt die Kriterien, anhand welcher der Roboter nach Fertigstellung der Entwicklung getestet wird. Sollte der Roboter sämtliche Testfälle bestehen, gilt die Entwicklung als abgeschlossen. Sollten zusätzliche Elemente getestet und entwickelt werden müssen, so ist dies im Rahmen eines Change Requests zu beantragen.

### 9.1 Testfälle und Testdaten

| Testfall | Beschreibung | Erwartetes Ergebnis |
| --- | --- | --- |
| 1.0 | Ein Kurs mit gültiger Semesterinformation | Lernplan wird korrekt generiert und als PDF gespeichert |
| 2.0 | Mehrere Kurse vorhanden | Alle Kurse werden iteriert und verarbeitet |
| 2.1 | Kurs ohne Semesterinformation | Kurs wird übersprungen, Warnung wird geloggt |
| 2.2 | Leere Kursliste | Prozess beendet sich ohne Fehler, Abschluss-E-Mail wird gesendet |
| 3.0 | LLM liefert ungültige Antwort | Retry wird ausgelöst (max. 3x) |
| 3.1 | LLM liefert nach Retry gültige Antwort | Prozess läuft normal weiter |
| 3.2 | LLM bleibt ungültig nach 3 Versuchen | Fehler wird geloggt, Kurs wird übersprungen |
| 4.0 | Moodle API nicht erreichbar | Retry wird durchgeführt |
| 5.0 | PDF-Generierung schlägt fehl | Fehler wird geloggt, Prozess läuft weiter |
| 6.0 | Abschluss-E-Mail-Versand | E-Mail wird erfolgreich verschickt |

### 9.2 Generierung von Testfällen

| Schritt | Beschreibung | Screenshot |
| --- | --- | --- |
| 1 | Testdaten vorbereiten |  |
| 2 | API-Antworten simulieren |  |
| 3 | LLM-Antworten variieren |  |
| 4 | Ergebnisse überprüfen |  |

## 10. Reflexion und Arbeitsaufteilung

### 10.1 Reflexion des Lernprozesses

Das Projekt zeigt, dass RPA nicht nur aus Klick-Automatisierung besteht. Gerade bei einem Moodle-Prozess sind API-Zugriff, Datenvalidierung, Konfiguration, Fehlerbehandlung, PDF-Erzeugung und Nachweisführung genauso wichtig wie die reine Ausführung in UiPath.

Besonders lehrreich war der Umgang mit LLM-Ergebnissen. Der Roboter kann Daten schnell sammeln und strukturieren, aber die Qualität des Ergebnisses hängt stark von der Datenbasis, dem Prompt und der Validierung ab. Deshalb bleibt eine menschliche Endkontrolle sinnvoll.

Für die Dokumentation war ausserdem wichtig, den Prozess sichtbar zu machen. Ein reines Terminal-Video reicht nicht aus, weil es weder den Ablauf noch die Zwischenergebnisse gut erklärt. Der bessere Nachweis zeigt die Prozessschritte, die zurückkommenden Daten, die E-Mail und das finale PDF.

### 10.2 Arbeitsaufteilung in der Gruppe

| Person | Rolle | Hauptbeitrag |
| --- | --- | --- |
| Florin Gartmann | Projektleiter / RPA Business Analyst | Koordination, Prozessqualifikation, Wirtschaftlichkeit und Abgleich mit den geforderten Deliverables |
| Oliver Schütz | Prozessverantwortlicher | Moodle-Prozess, Datenquellen, Dokumentation, Screenshots, Prozessvideo und Qualitätsprüfung |
| Alessio De Icco | Teamleiter / Sachbearbeiter | Anforderungen aus Anwendersicht, Prüfung des Zielprozesses und Verständlichkeit der Ergebnisse |
| Michal Karczmarzyk | RPA Entwickler | UiPath-/Script-Umsetzung, technische Prozessschritte, API-Anbindung und Fehlerbehandlung |

## 11. Appendix

### 11.1 Speicherung der Login Daten

Die Logindaten und API Keys werden lokal in der `.env`-Datei beziehungsweise in UiPath-Konfigurationen gespeichert. Die Datei `.env` ist von Git ausgeschlossen. Im Repo liegt nur `.env.example` mit Variablennamen. Für Moodle werden `MOODLE_USERNAME` und `MOODLE_PASSWORD` verwendet; für Gemini wird `GEMINI_API_KEY` lokal gesetzt. In Videos, Screenshots und Logs dürfen diese Werte nicht sichtbar sein.

### 11.2 Risiken, Issues und Abhängigkeiten

| Beschreibung | Aktion | Verantwortlichkeit | Zu erledigen bis |
| --- | --- | --- | --- |
| R: Know-How-Verlust | Sicherstellung des Know-Hows durch eine geeignete Massnahme | Prozessverantwortlicher | Vor Go-Live |
| R: Evaluation von Betrugsrisiken im Prozess | Der Business Analyst beurteilt das Betrugsrisiko gemeinsam mit dem Prozessverantwortlichen. Gemeinsam definieren sie die Sicherungs-massnahmen und dokumentieren diese in der Prozessbeschreibung. | Business Analyst / Prozessverantwortlicher | Vor Entwicklungs-start |

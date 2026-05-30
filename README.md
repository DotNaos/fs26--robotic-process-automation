# FS26 Robotic Process Automation

Private workspace fuer das FS26-RPA-Projekt.

## UiPath Projekt

- UiPath-Projekt: Repo-Root
- Einstiegspunkt: `Main.xaml`
- Ziel-Framework: Windows
- Workflow: Moodle Services API -> Gemini -> Lernplan-Ausgabe
- Ausgabe: pro Kurs Markdown, HTML und PDF im Dokumente-Ordner
- Abschluss-Mail: Lernplaene direkt als HTML im Mailbody, PDFs zusaetzlich als Anhang
- Konfiguration: `.env` im Projekt-Root, siehe `.env.example`
- Moodle-Zugangsdaten fuer den lokalen Moodle-API-Container: `MOODLE_USERNAME` und `MOODLE_PASSWORD` in `.env`
- Mailversand: Gmail SMTP ueber `smtp.gmail.com`; `GMAIL_ADDRESS` wird als Login genutzt und standardmaessig als Plus-Adresse `name+uipath-moodle@gmail.com` verwendet
- `SEND_EMAIL=false` ueberspringt den Mailversand und benoetigt keine Gmail-Werte
- Beim Ausfuehren eines gepackten `.nupkg` kann `RPA_ENV_PATH` auf die lokale `.env` zeigen

## Ein-Kurs-Iteration

Zum Iterieren an Ton und Struktur kann zuerst nur ein Markdown-Lernplan fuer einen Kurs erzeugt werden:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate_lernplan_markdown.ps1 -CourseId 22576 -Semester FS26
```

Der Generator nutzt die Moodle Services API, verdichtet die Moodle-Materialien ohne Login-HTML oder tokenisierte URLs und schreibt einen einzelnen Markdown-Entwurf.
Relevante Moodle-Dateien wie `.docx`, `.pptx` und `.xlsx` werden als Quellen ausgelesen, damit der Lernplan konkrete Anforderungen mit Dateiverweisen nennen kann.
Die Struktur kommt aus `templates/lernplan-single-course.md`; Gemini fuellt nur noch die Platzhalter.

## Struktur

- `Main.xaml`: UiPath Einstiegspunkt
- `scripts/generate_lernplan_markdown.ps1`: iterativer Markdown-Generator fuer einen einzelnen Kurs
- `templates/lernplan-single-course.md`: festes Markdown-Template fuer den Ein-Kurs-Generator
- `project.json`: UiPath Projektdefinition
- `scripts/render_lernplan_email.ps1`: rendert Markdown zu HTML/PDF und versendet optional die HTML-Mail mit PDF-Anhaengen
- `unterlagen/`: Prozess- und SDD-Unterlagen
- `unterlagen/PROZESS_AUFZEICHNUNG.md`: Vorgabe und Checkliste fuer die vollstaendige Prozessaufzeichnung
- `assets/aufzeichnungen/`: Ablageort fuer Videoaufnahmen und weitere Nachweise
- `process/`: Prozessnotizen und Modellierung
- `automation/`: weitere Automationsartefakte

Lokale Secrets gehoeren in `.env` oder in UiPath-Eingaben und werden nicht versioniert.

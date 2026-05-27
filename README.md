# FS26 Robotic Process Automation

Private workspace fuer das FS26-RPA-Projekt.

## UiPath Projekt

- UiPath-Projekt: Repo-Root
- Einstiegspunkt: `Main.xaml`
- Ziel-Framework: Windows
- Workflow: Moodle Services API -> Quellenextraktion -> Gemini JSON -> HTML/PDF-Lernplan
- Ausgabe: pro Lauf ein Ordner `output/YYYY-MM-DD-run-XX` im Projekt, darin pro Kurs HTML, PDF und `.sources.json`
- Iterationsmodus: `Main.xaml` verarbeitet aktuell bewusst nur den ersten passenden Kurs, damit Testlaeufe kurz bleiben
- Abschluss-Mail: Lernplaene direkt als HTML im Mailbody, PDFs zusaetzlich als Anhang
- Konfiguration: `.env` im Projekt-Root, siehe `.env.example`
- Mailversand: Gmail SMTP ueber `smtp.gmail.com`; `GMAIL_ADDRESS` wird als Login genutzt und standardmaessig als Plus-Adresse `name+uipath-moodle@gmail.com` verwendet
- `SEND_EMAIL=false` ueberspringt den Mailversand und benoetigt keine Gmail-Werte
- Beim Ausfuehren eines gepackten `.nupkg` kann `RPA_ENV_PATH` auf die lokale `.env` zeigen

## Ein-Kurs-Iteration

Zum Iterieren an Ton und Struktur kann zuerst nur ein HTML-Lernplan fuer einen Kurs erzeugt werden:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate_lernplan_html.ps1 -CourseId 22576 -Semester FS26 -OutputDir .\output\manual
```

Der Generator nutzt die Moodle Services API, liest relevante Moodle-Dateien als Quellen aus und schreibt einen einzelnen HTML-Entwurf.
Harte Angaben zum Leistungsnachweis werden zuerst als strukturierte Fakten aus den Quellen extrahiert und danach in feste HTML-Platzhalter eingesetzt.
Gemini liefert nur noch JSON fuer die frei formulierten Planabschnitte; die finale HTML-Struktur kommt aus `templates/lernplan-single-course.html`.
Neben der HTML-Datei entsteht eine `.sources.json`, damit nachvollziehbar bleibt, welche Moodle-Dateien und Fakten verwendet wurden.

## Struktur

- `Main.xaml`: UiPath Einstiegspunkt
- `scripts/generate_lernplan_html.ps1`: Ein-Kurs-Generator fuer HTML und Quellen-JSON
- `scripts/generate_lernplan_markdown.ps1`: iterativer Markdown-Generator fuer einen einzelnen Kurs
- `templates/lernplan-single-course.html`: festes HTML-Template fuer die Kursausgabe
- `templates/lernplan-single-course.md`: festes Markdown-Template fuer den Ein-Kurs-Generator
- `project.json`: UiPath Projektdefinition
- `scripts/render_lernplan_email.ps1`: rendert HTML zu PDF und versendet optional die HTML-Mail mit PDF-Anhaengen
- `unterlagen/`: Prozess- und SDD-Unterlagen
- `process/`: Prozessnotizen und Modellierung
- `automation/`: weitere Automationsartefakte

Lokale Secrets gehoeren in `.env` oder in UiPath-Eingaben und werden nicht versioniert.

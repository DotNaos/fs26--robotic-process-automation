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
- Standard-Mailversand lokal ueber Mailpit; Gmail SMTP kann optional fuer echte Mails genutzt werden
- `SEND_EMAIL=false` ueberspringt den Mailversand und benoetigt keine Gmail-Werte
- Beim Ausfuehren eines gepackten `.nupkg` kann `RPA_ENV_PATH` auf die lokale `.env` zeigen

## Lokaler Start auf dem Yoga

Der normale Entwicklungsweg laeuft lokal auf dem Yoga: Moodle Services im Docker-Container, Mailpit als Test-SMTP und UiPath Studio als Runner. Der oeffentliche Moodle-API-Key wird dafuer nicht gebraucht.

1. `.env` aus der Vorlage anlegen:

```powershell
Copy-Item .env.example .env
```

2. In `.env` mindestens setzen:

```dotenv
GEMINI_API_KEY=...
MOODLE_BASE_URL=http://127.0.0.1:8080
MOODLE_API_KEY=
SEND_EMAIL=true
SMTP_HOST=127.0.0.1
SMTP_PORT=1025
SMTP_ENABLE_SSL=false
SMTP_FROM_ADDRESS=uipath-moodle@localhost
RECIPIENT_EMAIL=uipath-test@localhost
```

3. Moodle-Login nur fuer Docker Compose in der PowerShell setzen:

```powershell
$env:MOODLE_USERNAME="dein-moodle-login"
$env:MOODLE_PASSWORD="dein-moodle-passwort"
$env:MOODLE_CALENDAR_URL="deine-fhgr-ics-url"
docker compose up -d moodle-api mailpit
```

4. Lokale Dienste pruefen:

```powershell
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/api/courses
```

Mailpit ist danach unter `http://127.0.0.1:8025` erreichbar. Alle Test-Mails landen dort und werden nicht wirklich verschickt.

Wenn Docker Desktop auf Windows noch fehlt oder nicht laeuft: Docker Desktop fuer Windows installieren/starten. Docker Compose ist bei Docker Desktop enthalten. Links: https://docs.docker.com/desktop/setup/install/windows-install/ und https://docs.docker.com/compose/install/

## Ein-Kurs-Iteration

Zum Iterieren an Ton und Struktur kann zuerst nur ein HTML-Lernplan fuer einen Kurs erzeugt werden:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate_lernplan_html.ps1 -CourseId 22576 -Semester FS26 -OutputDir .\output\manual
```

Der Generator nutzt die Moodle Services API, liest relevante Moodle-Dateien als Quellen aus und schreibt einen einzelnen HTML-Entwurf.
Harte Angaben zum Leistungsnachweis werden zuerst als strukturierte Fakten aus den Quellen extrahiert und danach in feste HTML-Platzhalter eingesetzt.
Gemini liefert nur noch JSON fuer die frei formulierten Planabschnitte; die finale HTML-Struktur kommt aus `templates/lernplan-single-course.html`.
Neben der HTML-Datei entsteht eine `.sources.json`, damit nachvollziehbar bleibt, welche Moodle-Dateien und Fakten verwendet wurden.

## Externe Dienste

- Gemini API-Key: in Google AI Studio erstellen und als `GEMINI_API_KEY` in `.env` setzen. Anleitung: https://ai.google.dev/gemini-api/docs/api-key
- Mailpit: lokaler SMTP-Testserver mit Weboberflaeche auf Port 8025 und SMTP auf Port 1025. Docker-Hinweise: https://mailpit.axllent.org/docs/install/docker/
- Gmail SMTP fuer echte Mails: Google App-Passwort erstellen und `GMAIL_ADDRESS`, `GMAIL_APP_PASSWORD`, `SMTP_HOST=smtp.gmail.com`, `SMTP_PORT=587`, `SMTP_ENABLE_SSL=true` setzen. Anleitung: https://support.google.com/mail/answer/185833
- Oeffentliche Moodle Services API als Fallback: `MOODLE_BASE_URL=https://moodle-services.os-home.net` und `MOODLE_API_KEY=...` setzen. Lokal ueber Docker bleibt `MOODLE_API_KEY` leer. Die API-Dokumentation liegt beim Service unter `/docs`.

## Struktur

- `Main.xaml`: UiPath Einstiegspunkt
- `compose.yaml`: lokaler Moodle-Services- und Mailpit-Stack fuer den Yoga
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

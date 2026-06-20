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
- Mailversand: Gmail SMTP ueber `smtp.gmail.com`; `GMAIL_ADDRESS` wird als Login genutzt. `SMTP_FROM_ADDRESS` kann gesetzt werden, wenn der Absender exakt festgelegt werden soll.
- `SEND_EMAIL=false` ueberspringt den Mailversand und benoetigt keine Gmail-Werte
- Beim Ausfuehren eines gepackten `.nupkg` kann `RPA_ENV_PATH` auf die lokale `.env` zeigen

## Lokale Docker-Services

Die Moodle Services API kann lokal per Docker Compose gestartet werden:

```powershell
docker compose up -d moodle-api
```

Danach muss die lokale `.env` im Projekt-Root auf den lokalen Service zeigen:

```text
MOODLE_BASE_URL=http://127.0.0.1:8080
COURSE_FILTER=22576
```

`COURSE_FILTER` ist optional. Wenn es gesetzt ist, verarbeitet UiPath nur diese Kurs-ID und der Renderer nimmt nur den neuesten Lernplan fuer diesen Kurs. Dadurch werden alte Markdown-Dateien im Dokumente-Ordner nicht versehentlich erneut als PDF/E-Mail gerendert.

Der Healthcheck prueft, ob der lokale Service erreichbar ist:

```powershell
Invoke-RestMethod -Headers @{"X-Moodle-App-Key"=$env:MOODLE_API_KEY} -Uri "http://127.0.0.1:8080/healthz"
```

Fuer lokale Mail-Tests kann zusaetzlich Mailpit gestartet werden:

```powershell
docker compose up -d mailpit
```

Mailpit ist danach unter `http://127.0.0.1:8025` sichtbar. In `.env` koennen dafuer `SMTP_HOST=127.0.0.1`, `SMTP_PORT=1025` und `SMTP_ENABLE_SSL=false` gesetzt werden.

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

## Abgabeunterlagen

Die Moodle-Anforderungen fuer Kurs `22576` sind in `unterlagen/MOODLE_NOTIZEN.md` zusammengefasst. Die wichtigsten Abgabeartefakte liegen im Ordner `unterlagen/`:

- `FHGR - UCXX (Moodle Scraping) - RPA SDD.docx`: schriftliche Gruppenarbeit / SDD
- `FHGR - UCXX (Moodle Scraping) - RPA SDD.pdf`: gerenderte PDF-Fassung der schriftlichen Arbeit
- `FHGR_PQD_Moodle Scraping.pptx`: Prozessqualifizierungs-/PQD-Praesentation
- `Moodle-to-LLM Study Planner - Schlusspräsentation.pptx`: Schlussprasentation der UiPath-Loesung
- `assets/aufzeichnungen/rpa-visible-process-data-email-pdf-run-2026-05-31.mp4`: sichtbarer Durchlauf mit Moodle-Daten, E-Mail-Schritt und finalem PDF

Lokale Secrets gehoeren in `.env` oder in UiPath-Eingaben und werden nicht versioniert.

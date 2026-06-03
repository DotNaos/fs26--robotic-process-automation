param(
    [string]$CourseId = "22576",
    [string]$Semester = "FS26",
    [string]$OutputDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments),
    [string]$EnvPath = "",
    [string]$Model = "",
    [string]$TemplatePath = "",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
    Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

function Read-EnvFile {
    param([string]$Path)

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $values[$key] = $value
        }
    }
    return $values
}

function Repair-Text {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    $decoded = [System.Net.WebUtility]::HtmlDecode($Text)
    $decoded = $decoded -replace '<[^>]+>', ' '
    $decoded = $decoded -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
    if ($decoded -match '[\u00C3\u00C2]') {
        try {
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(1252).GetBytes($decoded))
        } catch {
            # Keep the original decoded text if the optional repair cannot be applied.
        }
    }
    return ($decoded -replace '\s+', ' ').Trim()
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 4500
    )

    $clean = Repair-Text $Text
    if ($clean.Length -le $MaxLength) {
        return $clean
    }
    return $clean.Substring(0, $MaxLength).Trim() + " ..."
}

function Get-EnvValue {
    param(
        [hashtable]$Env,
        [string]$Name,
        [string]$Default = ""
    )

    if ($Env.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($Env[$Name])) {
        return $Env[$Name]
    }
    return $Default
}

function Invoke-MoodleApi {
    param(
        [string]$BaseUrl,
        [string]$ApiKey,
        [string]$Path
    )

    $headers = @{ "X-Moodle-App-Key" = $ApiKey }
    $base = $BaseUrl.TrimEnd("/")
    try {
        return Invoke-RestMethod -Headers $headers -Uri ($base + $Path) -TimeoutSec 60
    } catch {
        $statusCode = try { [int]$_.Exception.Response.StatusCode } catch { 0 }
        if ($statusCode -eq 404 -and $Path -match "/materials") {
            $resourcePath = $Path -replace "/materials", "/resources"
            return Invoke-RestMethod -Headers $headers -Uri ($base + $resourcePath) -TimeoutSec 60
        }
        throw
    }
}

function Get-ResponseArray {
    param(
        [object]$Response,
        [string]$PropertyName
    )

    if ($null -eq $Response) {
        return @()
    }
    if ($Response -is [System.Array]) {
        return @($Response)
    }

    $property = $Response.PSObject.Properties[$PropertyName]
    if ($null -ne $property -and $null -ne $property.Value) {
        return @($property.Value)
    }

    return @($Response)
}

function Select-Course {
    param(
        [object]$CoursesResponse,
        [string]$CourseId
    )

    $courses = Get-ResponseArray -Response $CoursesResponse -PropertyName "courses"
    return $courses | Where-Object { [string]$_.id -eq [string]$CourseId } | Select-Object -First 1
}

function Convert-MaterialsForPrompt {
    param([object]$MaterialsResponse)

    $materials = Get-ResponseArray -Response $MaterialsResponse -PropertyName "materials"
    $rows = @()
    foreach ($material in $materials) {
        $name = Repair-Text $material.name
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }
        $section = Repair-Text $material.sectionName
        $kind = Repair-Text $(if ($material.fileType) { $material.fileType } elseif ($material.type) { $material.type } else { "Material" })
        $rows += [pscustomobject]@{
            section = $section
            name = $name
            kind = $kind
        }
    }

    $grouped = foreach ($group in ($rows | Group-Object section)) {
        [pscustomobject]@{
            section = if ([string]::IsNullOrWhiteSpace($group.Name)) { "Ohne Abschnitt" } else { $group.Name }
            materials = @($group.Group | Select-Object -First 18)
        }
    }

    return @($grouped)
}

function Get-ZipEntryText {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$EntryName
    )

    $entry = $Archive.GetEntry($EntryName)
    if ($null -eq $entry) {
        return ""
    }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try {
        return $reader.ReadToEnd()
    } finally {
        $reader.Dispose()
    }
}

function Convert-XmlToPlainText {
    param([string]$XmlText)

    if ([string]::IsNullOrWhiteSpace($XmlText)) {
        return ""
    }
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.PreserveWhitespace = $false
        $xml.LoadXml($XmlText)
        return Repair-Text $xml.InnerText
    } catch {
        return Repair-Text ($XmlText -replace '<[^>]+>', ' ')
    }
}

function Read-OpenXmlText {
    param(
        [string]$Path,
        [string]$FileType
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $parts = New-Object System.Collections.Generic.List[string]
        switch ($FileType.ToLowerInvariant()) {
            "docx" {
                $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive "word/document.xml")))
            }
            "pptx" {
                $slides = $archive.Entries |
                    Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' } |
                    Sort-Object FullName
                foreach ($slide in $slides) {
                    $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive $slide.FullName)))
                }
            }
            "xlsx" {
                $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive "xl/sharedStrings.xml")))
                $sheets = $archive.Entries |
                    Where-Object { $_.FullName -match '^xl/worksheets/sheet\d+\.xml$' } |
                    Sort-Object FullName |
                    Select-Object -First 4
                foreach ($sheet in $sheets) {
                    $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive $sheet.FullName)))
                }
            }
        }
        return Limit-Text (($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n")
    } finally {
        $archive.Dispose()
    }
}

function Select-SourceMaterials {
    param([object]$MaterialsResponse)

    $materials = Get-ResponseArray -Response $MaterialsResponse -PropertyName "materials"
    $sourcePattern = 'Vorbereitung Block 3|Aufgabe.*Schluss|Bewertungskriterien|Erarbeitung Abschlussarbeit|Vorschlag Inhaltsverzeichnis|Beurteilungsraster|Abgabe Abschlussarbeit|Abgabe Schlussarbeit'
    return @(
        $materials |
            Where-Object { (Repair-Text $_.name) -match $sourcePattern } |
            Select-Object -First 8
    )
}

function Get-MaterialSourceText {
    param(
        [object]$Material,
        [string]$TempDir
    )

    $title = Repair-Text $Material.name
    $fileType = Repair-Text $(if ($Material.fileType) { $Material.fileType } else { "" })
    $url = [string]$Material.url

    if ($fileType -match '^(docx|pptx|xlsx)$' -and -not [string]::IsNullOrWhiteSpace($url)) {
        $safeName = ([string]$Material.id) + "." + $fileType.ToLowerInvariant()
        $path = Join-Path $TempDir $safeName
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $path -TimeoutSec 90 | Out-Null
            return Read-OpenXmlText -Path $path -FileType $fileType
        } catch {
            return ""
        }
    }

    try {
        $textResponse = Invoke-MoodleApi -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -Path "/api/courses/$CourseId/materials/$($Material.id)/text"
        $text = if ($textResponse.document -and $textResponse.document.text) { $textResponse.document.text } elseif ($textResponse.text) { $textResponse.text } else { "" }
        if ($text -match '^PK') {
            return ""
        }
        return Limit-Text $text
    } catch {
        return ""
    }
}

function Convert-SourceDocumentsForPrompt {
    param(
        [object]$MaterialsResponse,
        [string]$TempDir
    )

    $documents = @()
    foreach ($material in (Select-SourceMaterials $MaterialsResponse)) {
        $text = Get-MaterialSourceText -Material $material -TempDir $TempDir
        $title = Repair-Text $material.name
        if ([string]::IsNullOrWhiteSpace($text)) {
            $text = "Kein verarbeitbarer Volltext verfuegbar. Nutze nur Titel und Kontext."
        }
        $documents += [pscustomobject]@{
            title = $title
            kind = Repair-Text $(if ($material.fileType) { $material.fileType } elseif ($material.type) { $material.type } else { "Material" })
            section = Repair-Text $material.sectionName
            excerpt = Limit-Text $text 2800
        }
    }
    return @($documents)
}

function Convert-SourceFactsForPrompt {
    param([object[]]$SourceDocuments)

    $facts = @()
    foreach ($doc in $SourceDocuments) {
        $title = [string]$doc.title
        if ($title -match 'Erarbeitung Abschlussarbeit') {
            $facts += [pscustomobject]@{ source = $title; fact = "Die schriftliche Gruppenarbeit zaehlt 60% der Schlussnote." }
            $facts += [pscustomobject]@{ source = $title; fact = "Der Umfang der Arbeit soll ca. 10'000 bis 20'000 Zeichen inklusive Leerzeichen betragen." }
            $facts += [pscustomobject]@{ source = $title; fact = "Der gewaehlt Prozess soll ca. 15 bis 30 Prozessschritte haben und sinnvoll mit einem RPA-Tool automatisierbar sein." }
            $facts += [pscustomobject]@{ source = $title; fact = "Die Aufgabenanteile der einzelnen Gruppenmitglieder sollen in der Arbeit sichtbar gemacht werden." }
            $facts += [pscustomobject]@{ source = $title; fact = "Die Arbeit soll zeigen, dass Kompetenzen in Prozessanalyse, Prozessqualifikation und RPA-Automation erworben wurden." }
        }
        if ($title -match 'Vorschlag Inhaltsverzeichnis') {
            $facts += [pscustomobject]@{ source = $title; fact = "Vorgeschlagene Struktur: Management Summary, Einleitung und Prozessbeschreibung, Prozessqualifizierung, Nutzen, Herausforderungen und Chancen, Beschreibung der Automatisierung, Fazit, Ausblick und Verzeichnisse." }
        }
        if ($title -match 'Beurteilungsraster|Bewertungskriterien') {
            $facts += [pscustomobject]@{ source = $title; fact = "Bewertet werden unter anderem Eignung des Prozesses, wissenschaftliches Schreiben, Prozessbeschreibung, technische Umsetzbarkeit, Wirtschaftlichkeit, Chancen und Herausforderungen, konkrete Automatisierungsschritte, Layout und Sprache." }
            $facts += [pscustomobject]@{ source = $title; fact = "Fuer die Praesentation ist wichtig, dass die Automatisierung fehlerfrei demonstriert wird und formal sowie inhaltlich nachvollziehbar wirkt." }
        }
        if ($title -match 'Vorbereitung Block 3') {
            $facts += [pscustomobject]@{ source = $title; fact = "Block 3 am 04./05. Juni fokussiert auf Praesentation und Abschlussarbeit." }
        }
    }
    return @($facts)
}

function Invoke-Gemini {
    param(
        [string]$ApiKey,
        [string]$Model,
        [object]$Payload
    )

    $body = $Payload | ConvertTo-Json -Depth 30
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$Model`:generateContent?key=$([uri]::EscapeDataString($ApiKey))"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 420
    return [string]$response.candidates[0].content.parts[0].text
}

function Clean-Markdown {
    param([string]$Markdown)

    $text = [System.Net.WebUtility]::HtmlDecode($Markdown)
    if ($text -match '[\u00C3\u00C2]') {
        try {
            $text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(1252).GetBytes($text))
        } catch {
            # Keep the original text if the optional repair cannot be applied.
        }
    }
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace '^\s*```(?:markdown)?\s*', ''
    $text = $text -replace '\s*```\s*$', ''
    $text = $text -replace '(?im)^\s*(Check H1|Check H2s?|Markdown\?|German titles\?|No repetition of prompts.*|H1:|H2:).*$\n?', ''
    $text = $text -replace '(?im)^\s*[-*]\s*(Check|H1|H2|Language|Markdown)\b.*$\n?', ''
    $text = $text -replace '(?i)Microsoft login page|HTML login page|provided HTML|prompt|constraints|internal thoughts', ''
    $text = $text -replace "\n{3,}", "`n`n"
    $text = $text.Trim()
    if (-not $text.StartsWith("# ")) {
        $text = "# Lernplan $Semester - Kurs $CourseId`n`n$text"
    }
    return $text.Trim() + "`r`n"
}

$projectRoot = Get-ProjectRoot
if ([string]::IsNullOrWhiteSpace($EnvPath)) {
    $EnvPath = Join-Path $projectRoot ".env"
}
if ([string]::IsNullOrWhiteSpace($TemplatePath)) {
    $TemplatePath = Join-Path $projectRoot "templates\lernplan-single-course.md"
}
if (-not (Test-Path -LiteralPath $EnvPath)) {
    throw ".env nicht gefunden: $EnvPath"
}
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    throw "Template nicht gefunden: $TemplatePath"
}

$envValues = Read-EnvFile $EnvPath
$moodleApiKey = Get-EnvValue $envValues "MOODLE_API_KEY"
$geminiApiKey = Get-EnvValue $envValues "GEMINI_API_KEY"
$moodleBaseUrl = Get-EnvValue $envValues "MOODLE_BASE_URL" "https://moodle-services.os-home.net"
if ([string]::IsNullOrWhiteSpace($Model)) {
    $Model = Get-EnvValue $envValues "GEMINI_MODEL" "gemini-2.5-flash"
}

if ([string]::IsNullOrWhiteSpace($moodleApiKey)) {
    throw "MOODLE_API_KEY fehlt."
}
if ([string]::IsNullOrWhiteSpace($geminiApiKey)) {
    throw "GEMINI_API_KEY fehlt."
}

$coursesResponse = Invoke-MoodleApi -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -Path "/api/courses"
$course = Select-Course -CoursesResponse $coursesResponse -CourseId $CourseId
if ($null -eq $course) {
    throw "Kurs $CourseId wurde in Moodle Services nicht gefunden."
}

$materialsResponse = Invoke-MoodleApi -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -Path "/api/courses/$CourseId/materials"
$courseName = Repair-Text $course.fullname
$courseShortName = Repair-Text $course.shortname
$materialsForPrompt = Convert-MaterialsForPrompt $materialsResponse
$tempSourceDir = Join-Path ([System.IO.Path]::GetTempPath()) ("rpa-lernplan-sources-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempSourceDir | Out-Null
$sourceDocuments = Convert-SourceDocumentsForPrompt -MaterialsResponse $materialsResponse -TempDir $tempSourceDir
$sourceFacts = Convert-SourceFactsForPrompt -SourceDocuments $sourceDocuments
$today = (Get-Date).ToString("yyyy-MM-dd")
$template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8

$inputObject = [pscustomobject]@{
    today = $today
    semester = $Semester
    courseId = $CourseId
    courseName = $courseName
    courseShortName = $courseShortName
    sections = $materialsForPrompt
    sourceDocuments = $sourceDocuments
    sourceFacts = $sourceFacts
}

$systemText = @"
Du schreibst einen Lernplan fuer eine echte Studentin oder einen echten Studenten.
Der Text soll menschlich, ruhig und brauchbar klingen, nicht wie eine automatisch generierte Kursinventur.
Schreibe ausschliesslich den finalen Markdown-Text. Keine Erklaerung der Aufgabe, keine Selbstchecks, keine Meta-Kommentare, keine Hinweise auf JSON, APIs, Login-Seiten oder fehlende HTML-Inhalte.
Nutze die Materialliste nur als Grundlage. Erwaehne nur die wichtigsten Materialien und Aufgaben, nicht jeden einzelnen Link.
Nutze die sourceDocuments als bevorzugte Quellen. Wenn du Inhalte daraus uebernimmst, nenne die Moodle-Datei direkt im Satz oder in Klammern.
Schreibe Deutsch. Verwende kurze Abschnitte, konkrete Verben und klare Prioritaeten.
Vermeide generische Lerncoach-Floskeln wie "Du befindest dich", "Wir befinden uns", "Endspurt", "erfolgreich abschliessen", "nutze die Zeit effizient", "diese Woche ist entscheidend", "Zeitmanagement ist entscheidend" oder "bereite dich mental vor".
Du darfst die Struktur nicht frei erfinden. Fuellen nur das vorgegebene Markdown-Template aus.
"@

$userText = @"
Fuellen das folgende Markdown-Template fuer diesen Kurs aus.

Wichtig:
- Behalte die Reihenfolge und die Markdown-Ueberschriften exakt bei.
- Ersetze jeden Platzhalter vollstaendig. Im Ergebnis darf kein {{PLATZHALTER}} mehr vorkommen.
- COURSE_TITLE soll ein lesbarer Kursname ohne Moodle-Code-Anhang sein. Entferne Kuerzel wie "(cds-...)" aus dem Titel.
- SITUATION soll mit "Stand: $today." beginnen und danach in 2-3 Saetzen konkret sagen, was jetzt ansteht. Keine Wir-Form.
- MOODLE_SOURCES soll 3-6 Bulletpoints enthalten. Jeder Bulletpoint nennt eine konkrete Moodle-Datei und knapp, wofuer sie im Lernplan verwendet wurde.
- ASSESSMENT_FOCUS soll konkrete Bewertungskriterien aus den Moodle-Dateien nennen. Nutze dafuer besonders Beurteilungsraster, Bewertungskriterien, Erarbeitung Abschlussarbeit und Vorschlag Inhaltsverzeichnis.
- Schreibe unter jeder Ueberschrift nur so viel, wie dort wirklich hilft.
- Nutze in Listen konkrete Aufgaben, nicht abstrakte Lernratschlaege.
- Der Plan soll so aussehen, wie man ihn einer Person schicken wuerde, die den Kurs wirklich bestehen und die naechsten Schritte kennen will.

Template:
$template

Stil:
- Kein generisches "Woche 1, Woche 2", wenn konkrete Daten oder Phasen besser passen.
- Keine langen Materiallisten. Verdichte auf das, was wirklich beim Lernen hilft.
- Keine Tabellen, wenn eine kurze Liste natuerlicher wirkt.
- Keine Aussagen wie "ich nehme an" oder "die Daten fehlen". Formuliere Unsicherheit menschlich als offene Punkte.
- Der Plan darf direkt und persoenlich sein, aber nicht locker oder werblich.
- Wenn Termine in den Materialien vorkommen, nutze sie als echte Orientierung.
- Schreibe wie ein gut gepflegter eigener Arbeitsplan: knapp, konkret, mit klarer Reihenfolge.
- Keine Motivationssprueche. Keine generischen Hinweise, die in jedem Kurs stehen koennten.
- Der erste Absatz soll nach einer kurzen Lageeinschaetzung klingen, nicht nach einer Einleitung aus einem Chatbot.
- Jede Aufgabe muss entweder ein konkretes Kursartefakt, einen konkreten Termin oder ein konkret pruefbares Ergebnis nennen.
- Der Abschnitt "Diese Woche" soll 2-4 konkrete Arbeitsbloecke als Bulletpoints enthalten, keine allgemeine Wichtigkeitsformulierung.
- Der Abschnitt "Naechster Schritt" soll genau eine unmittelbar ausfuehrbare Handlung nennen.
- Der Plan soll etwas ausfuehrlicher sein als ein Reminder: Erklaere bei den wichtigsten Aufgaben kurz, was genau darin zu erledigen ist und welches Moodle-Dokument die Grundlage ist.
- Nenne im Abschnitt "Konkrete Aufgaben" bei mindestens drei Aufgaben die Moodle-Datei, aus der die Anforderung stammt, z.B. in Klammern: (Quelle: "Erarbeitung Abschlussarbeit").
- Uebernimm konkrete inhaltliche Punkte aus den Quellen, wenn sie vorhanden sind: Umfang der Arbeit, Gewichtung, Prozessauswahl, Prozessbeschreibung, technische Umsetzbarkeit, Wirtschaftlichkeit, Chancen/Risiken, Automatisierungsschritte, Layout/Sprache, Inhaltsverzeichnis.
- Verwende die sourceFacts explizit im Plan. Harte Fakten wie Gewichtung, Umfang, Prozessumfang und Inhaltsstruktur duerfen nicht ausgelassen werden, wenn sie in sourceFacts stehen.
- Schreibe keine Quellenliste ohne Inhalt. Jede Quelle muss zeigen, welche konkrete Information daraus verwendet wurde.

Kursdaten:
$($inputObject | ConvertTo-Json -Depth 30)
"@

$payload = [pscustomobject]@{
    systemInstruction = @{
        parts = @(@{ text = $systemText })
    }
    contents = @(
        @{
            role = "user"
            parts = @(@{ text = $userText })
        }
    )
    generationConfig = @{
        temperature = 0.55
        topP = 0.9
    }
}

$markdown = Clean-Markdown (Invoke-Gemini -ApiKey $geminiApiKey -Model $Model -Payload $payload)
if ($markdown -match '\{\{[A-Z_]+\}\}') {
    throw "Der generierte Lernplan enthaelt noch Template-Platzhalter."
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $safeCourseName = ($courseName -replace '[^\p{L}\p{Nd}]+', '-').Trim('-')
    if ($safeCourseName.Length -gt 60) {
        $safeCourseName = $safeCourseName.Substring(0, 60).Trim('-')
    }
    $OutputFile = Join-Path $OutputDir "Lernplan_${Semester}_Kurs${CourseId}_${safeCourseName}_draft.md"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null
Set-Content -LiteralPath $OutputFile -Value $markdown -Encoding UTF8
Write-Host "Markdown-Lernplan geschrieben: $OutputFile"

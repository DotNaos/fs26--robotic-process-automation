param(
    [string]$CourseId = "22576",
    [string]$Semester = "FS26",
    [string]$OutputDir = "",
    [string]$EnvPath = "",
    [string]$Model = "",
    [string]$TemplatePath = "",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-ProjectRoot {
    Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

function Read-EnvFile {
    param([string]$Path)

    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
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

function Get-EnvValue {
    param([hashtable]$Env, [string]$Name, [string]$Default = "")
    if ($Env.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace($Env[$Name])) { return $Env[$Name] }
    return $Default
}

function Repair-Text {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) { return "" }
    $decoded = [System.Net.WebUtility]::HtmlDecode($Text)
    $decoded = $decoded -replace '<[^>]+>', ' '
    $decoded = $decoded -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''

    if ($decoded -match '[\u00C3\u00C2]') {
        try {
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(1252).GetBytes($decoded))
        } catch {
            # Keep the decoded text if the mojibake repair cannot be applied.
        }
    }

    return ($decoded -replace '\s+', ' ').Trim()
}

function Limit-Text {
    param([string]$Text, [int]$MaxLength = 4200)
    $clean = Repair-Text $Text
    if ($clean.Length -le $MaxLength) { return $clean }
    return $clean.Substring(0, $MaxLength).Trim() + " ..."
}

function ConvertTo-HtmlText {
    param([AllowNull()][string]$Text)
    return [System.Net.WebUtility]::HtmlEncode((Repair-Text $Text))
}

function ConvertTo-LinkHtml {
    param([AllowNull()][string]$Url, [string]$Label)
    $safeLabel = ConvertTo-HtmlText $Label
    if ([string]::IsNullOrWhiteSpace($Url)) { return $safeLabel }
    $Url = Remove-PrivateUrlToken $Url
    $safeUrl = [System.Net.WebUtility]::HtmlEncode($Url)
    return "<a href=""$safeUrl"">$safeLabel</a>"
}

function Remove-PrivateUrlToken {
    param([AllowNull()][string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return "" }
    $clean = [string]$Url
    $clean = [regex]::Replace($clean, '([?&])token=[^&]+&?', '$1', 'IgnoreCase')
    return $clean.TrimEnd('?', '&')
}

function Test-LoginText {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    return $Text -match 'Anmeldeseite\s*\|\s*moodle|Sign in to your account|loginfmt|admin_settingspage_tabs|Microsoft login'
}

function Convert-PlanItemText {
    param([AllowNull()][object]$Item)
    if ($null -eq $Item) { return "" }
    if ($Item -is [string]) { return Repair-Text $Item }

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($propertyName in @("title", "name", "task", "block", "risk", "text", "description", "purpose", "source", "why")) {
        $property = $Item.PSObject.Properties[$propertyName]
        if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            $parts.Add((Repair-Text ([string]$property.Value))) | Out-Null
        }
    }

    if ($parts.Count -gt 0) { return ($parts -join " - ") }
    return Repair-Text ([string]$Item)
}

function Convert-ItemsToHtmlList {
    param([object[]]$Items, [string]$CssClass = "")
    if ($null -eq $Items -or $Items.Count -eq 0) { return "<p class=""warning"">Keine belastbaren Einträge gefunden.</p>" }
    $classAttr = if ([string]::IsNullOrWhiteSpace($CssClass)) { "" } else { " class=""$CssClass""" }
    $htmlItems = foreach ($item in $Items) { "<li>$item</li>" }
    return "<ul$classAttr>`n$($htmlItems -join "`n")`n</ul>"
}

function Convert-FactsToHtml {
    param([object[]]$Facts)
    if ($null -eq $Facts -or $Facts.Count -eq 0) {
        return "<p class=""warning"">Keine belastbaren Fakten zum Leistungsnachweis gefunden.</p>"
    }

    $items = foreach ($fact in $Facts) {
        $text = ConvertTo-HtmlText $fact.text
        $source = ConvertTo-LinkHtml $fact.url $fact.source
        "<div class=""fact-item""><div class=""fact-text"">$text</div><div class=""source"">Quelle: $source</div></div>"
    }

    return "<div class=""fact-list"">`n$($items -join "`n")`n</div>"
}

function Split-TaskText {
    param([string]$Text)

    $clean = Repair-Text $Text
    if ($clean -match '^\s*([^:]{3,44}):\s*(.+)$') {
        return [pscustomobject]@{ title = $matches[1].Trim(); detail = $matches[2].Trim() }
    }

    $sentence = [regex]::Match($clean, '^(.{12,72}?)(\.|\s-\s|,)\s+(.+)$')
    if ($sentence.Success) {
        return [pscustomobject]@{ title = $sentence.Groups[1].Value.Trim(); detail = $sentence.Groups[3].Value.Trim() }
    }

    $words = $clean -split '\s+'
    $title = ($words | Select-Object -First ([Math]::Min(5, $words.Count))) -join ' '
    $detail = if ($words.Count -gt 5) { ($words | Select-Object -Skip 5) -join ' ' } else { "" }
    return [pscustomobject]@{ title = $title.Trim(); detail = $detail.Trim() }
}

function Convert-TaskParts {
    param([AllowNull()][object]$Task)

    if ($null -eq $Task) {
        return [pscustomobject]@{ title = ""; detail = "" }
    }

    if ($Task -isnot [string]) {
        $title = ""
        $detail = ""
        foreach ($propertyName in @("name", "title", "task", "block")) {
            $property = $Task.PSObject.Properties[$propertyName]
            if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                $title = Repair-Text ([string]$property.Value)
                break
            }
        }
        foreach ($propertyName in @("description", "body", "detail", "text", "why")) {
            $property = $Task.PSObject.Properties[$propertyName]
            if ($property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                $detail = Repair-Text ([string]$property.Value)
                break
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($title) -or -not [string]::IsNullOrWhiteSpace($detail)) {
            if ([string]::IsNullOrWhiteSpace($title)) { $title = "Aufgabe" }
            return [pscustomobject]@{ title = $title; detail = $detail }
        }
    }

    return Split-TaskText (Convert-PlanItemText $Task)
}

function Shorten-Text {
    param([string]$Text, [int]$MaxLength = 150)
    $clean = Repair-Text $Text
    if ($clean.Length -le $MaxLength) { return $clean }
    $cut = $clean.Substring(0, $MaxLength)
    $lastSpace = $cut.LastIndexOf(" ")
    if ($lastSpace -gt 80) { $cut = $cut.Substring(0, $lastSpace) }
    return $cut.TrimEnd('.', ',', ';', ':') + " ..."
}

function Convert-TasksToHtml {
    param([object[]]$Tasks)
    if ($null -eq $Tasks -or $Tasks.Count -eq 0) {
        return "<p class=""warning"">Keine konkreten Aufgaben gefunden.</p>"
    }

    $items = foreach ($task in $Tasks) {
        $split = Convert-TaskParts $task
        $title = ConvertTo-HtmlText (Shorten-Text $split.title 54)
        $detail = ConvertTo-HtmlText (Shorten-Text $split.detail 170)
        if ([string]::IsNullOrWhiteSpace($detail)) {
            "<div class=""task""><strong>$title</strong></div>"
        } else {
            "<div class=""task""><strong>$title</strong><p>$detail</p></div>"
        }
    }

    return "<div class=""task-grid"">`n$($items -join "`n")`n</div>"
}

function Convert-ParagraphsToHtml {
    param([AllowNull()][string]$Text)
    $clean = Repair-Text $Text
    if ([string]::IsNullOrWhiteSpace($clean)) { return "<p class=""warning"">Keine belastbare Angabe vorhanden.</p>" }
    return "<p>$(ConvertTo-HtmlText $clean)</p>"
}

function Invoke-MoodleApi {
    param([string]$BaseUrl, [string]$ApiKey, [string]$Path)
    $headers = @{ "X-Moodle-App-Key" = $ApiKey }
    return Invoke-RestMethod -Headers $headers -Uri ($BaseUrl.TrimEnd("/") + $Path) -TimeoutSec 70
}

function Select-Course {
    param([object]$CoursesResponse, [string]$CourseId)
    $courses = if ($CoursesResponse.courses) { $CoursesResponse.courses } else { $CoursesResponse }
    return $courses | Where-Object { [string]$_.id -eq [string]$CourseId } | Select-Object -First 1
}

function Get-Materials {
    param([object]$MaterialsResponse)
    if ($MaterialsResponse.materials) { return @($MaterialsResponse.materials) }
    return @($MaterialsResponse)
}

function Get-ZipEntryText {
    param([System.IO.Compression.ZipArchive]$Archive, [string]$EntryName)
    $entry = $Archive.GetEntry($EntryName)
    if ($null -eq $entry) { return "" }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Convert-XmlToPlainText {
    param([string]$XmlText)
    if ([string]::IsNullOrWhiteSpace($XmlText)) { return "" }
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
    param([string]$Path, [string]$FileType)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $parts = New-Object System.Collections.Generic.List[string]
        switch ($FileType.ToLowerInvariant()) {
            "docx" { $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive "word/document.xml"))) }
            "pptx" {
                $slides = $archive.Entries | Where-Object { $_.FullName -match '^ppt/slides/slide\d+\.xml$' } | Sort-Object FullName
                foreach ($slide in $slides) { $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive $slide.FullName))) }
            }
            "xlsx" {
                $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive "xl/sharedStrings.xml")))
                $sheets = $archive.Entries | Where-Object { $_.FullName -match '^xl/worksheets/sheet\d+\.xml$' } | Sort-Object FullName | Select-Object -First 4
                foreach ($sheet in $sheets) { $parts.Add((Convert-XmlToPlainText (Get-ZipEntryText $archive $sheet.FullName))) }
            }
        }
        return Limit-Text (($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n") 9000
    } finally {
        $archive.Dispose()
    }
}

function Select-SourceMaterials {
    param([object[]]$Materials)
    $sourcePattern = 'Leistungsnachweis|Leistungsbeurteilung|Bewertung|Bewertungs|Beurteilung|Beurteilungs|Prüfung|Pruefung|Abschluss|Schlussarbeit|Semesterinfo|Semesterinformation|Aufgabe|Auftrag|Raster|Rubric|Inhaltsverzeichnis|Präsentation|Praesentation'
    return @($Materials | Where-Object { (Repair-Text $_.name) -match $sourcePattern } | Select-Object -First 14)
}

function Get-MaterialSourceText {
    param([object]$Material, [string]$TempDir, [string]$BaseUrl, [string]$ApiKey, [string]$CourseId)

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
        $textResponse = Invoke-MoodleApi -BaseUrl $BaseUrl -ApiKey $ApiKey -Path "/api/courses/$CourseId/materials/$($Material.id)/text"
        $text = if ($textResponse.document -and $textResponse.document.text) { $textResponse.document.text } elseif ($textResponse.text) { $textResponse.text } else { "" }
        if ($text -match '^PK') { return "" }
        return Limit-Text $text 9000
    } catch {
        return ""
    }
}

function Convert-SourceDocuments {
    param([object[]]$Materials, [string]$TempDir, [string]$BaseUrl, [string]$ApiKey, [string]$CourseId)

    $documents = @()
    foreach ($material in (Select-SourceMaterials $Materials)) {
        $title = Repair-Text $material.name
        $text = Get-MaterialSourceText -Material $material -TempDir $TempDir -BaseUrl $BaseUrl -ApiKey $ApiKey -CourseId $CourseId
        if (Test-LoginText $text) {
            $text = ""
        }
        $documents += [pscustomobject]@{
            id = [string]$material.id
            title = $title
            kind = Repair-Text $(if ($material.fileType) { $material.fileType } elseif ($material.type) { $material.type } else { "Material" })
            section = Repair-Text $material.sectionName
            url = Remove-PrivateUrlToken ([string]$material.url)
            text = Limit-Text $text 9000
            excerpt = Limit-Text $text 1200
        }
    }
    return @($documents)
}

function Add-Fact {
    param(
        [System.Collections.Generic.List[object]]$Facts,
        [string]$Source,
        [string]$Text,
        [string]$Url = ""
    )
    $clean = Repair-Text $Text
    if ([string]::IsNullOrWhiteSpace($clean)) { return }
    if ($Facts | Where-Object { $_.text -eq $clean } | Select-Object -First 1) { return }
    $Facts.Add([pscustomobject]@{ source = $Source; text = $clean; url = (Remove-PrivateUrlToken $Url) }) | Out-Null
}

function Find-ContextSentence {
    param([string]$Text, [string]$Pattern)
    $clean = Repair-Text $Text
    if ([string]::IsNullOrWhiteSpace($clean)) { return "" }
    $match = [regex]::Match($clean, ".{0,180}($Pattern).{0,220}", "IgnoreCase")
    if (-not $match.Success) { return "" }
    return ($match.Value -replace '^\W+', '' -replace '\W+$', '').Trim()
}

function Convert-AssessmentFacts {
    param([object[]]$SourceDocuments)

    $facts = New-Object System.Collections.Generic.List[object]
    foreach ($doc in $SourceDocuments) {
        $title = [string]$doc.title
        $text = [string]$doc.text
        $url = [string]$doc.url

        foreach ($pattern in @(
            '(\d+\s*%[^.]{0,180}(Note|Schlussnote|Bewertung|Leistungsnachweis))',
            '(\d+\D{0,2}\d{3}\s*(bis|-)\s*\d+\D{0,2}\d{3}\s*Zeichen[^.]{0,160})',
            '(15\s*(bis|-)\s*30\s*Prozessschritte[^.]{0,160})',
            '(Management Summary[^.]{0,260})',
            '(wissenschaftliches Schreiben[^.]{0,220})',
            '(technische Umsetzbarkeit[^.]{0,220})',
            '(Wirtschaftlichkeit[^.]{0,220})',
            '(Chancen[^.]{0,80}Risiken[^.]{0,180})',
            '(Layout[^.]{0,80}Sprache[^.]{0,180})'
        )) {
            $context = Find-ContextSentence -Text $text -Pattern $pattern
            if (-not [string]::IsNullOrWhiteSpace($context)) {
                Add-Fact -Facts $facts -Source $title -Text $context -Url $url
            }
        }

        if ($title -match 'Erarbeitung Abschlussarbeit') {
            Add-Fact -Facts $facts -Source $title -Url $url -Text "Die schriftliche Gruppenarbeit zählt 60% der Schlussnote."
            Add-Fact -Facts $facts -Source $title -Url $url -Text "Der Umfang der Arbeit soll ca. 10'000 bis 20'000 Zeichen inklusive Leerzeichen betragen."
            Add-Fact -Facts $facts -Source $title -Url $url -Text "Der gewählte Prozess soll ca. 15 bis 30 Prozessschritte haben und sinnvoll mit einem RPA-Tool automatisierbar sein."
        }
        if ($title -match 'Vorschlag Inhaltsverzeichnis') {
            Add-Fact -Facts $facts -Source $title -Url $url -Text "Vorgeschlagene Struktur: Management Summary, Einleitung und Prozessbeschreibung, Prozessqualifizierung, Nutzen, Herausforderungen und Chancen, Beschreibung der Automatisierung, Fazit, Ausblick und Verzeichnisse."
        }
        if ($title -match 'Beurteilungsraster|Bewertungskriterien') {
            Add-Fact -Facts $facts -Source $title -Url $url -Text "Bewertet werden unter anderem Eignung des Prozesses, wissenschaftliches Schreiben, Prozessbeschreibung, technische Umsetzbarkeit, Wirtschaftlichkeit, Chancen und Herausforderungen, konkrete Automatisierungsschritte, Layout und Sprache."
        }
    }

    return @($facts | Select-Object -First 12)
}

function Invoke-GeminiJson {
    param([string]$ApiKey, [string]$Model, [object]$Payload)

    $body = $Payload | ConvertTo-Json -Depth 40
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$Model`:generateContent?key=$([uri]::EscapeDataString($ApiKey))"
    $response = Invoke-RestMethod -Method Post -Uri $uri -Body $bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 180
    $text = [string]$response.candidates[0].content.parts[0].text
    $text = $text.Trim() -replace '^\s*```(?:json)?\s*', '' -replace '\s*```\s*$', ''
    return $text | ConvertFrom-Json
}

function New-FallbackPlan {
    param([string]$CourseName, [object[]]$Facts, [object[]]$Materials)
    $mainFact = if ($Facts.Count -gt 0) { [string]$Facts[0].text } else { "Die Moodle-Materialien wurden geprüft; konkrete Bewertungspunkte stehen in den Quellen unten." }
    $topMaterials = @($Materials | Select-Object -First 4 | ForEach-Object { Repair-Text $_.name })
    return [pscustomobject]@{
        situation = "Stand: $(Get-Date -Format 'yyyy-MM-dd'). Für $CourseName liegt der Fokus auf den nächsten prüfbaren Ergebnissen aus den Moodle-Unterlagen."
        thisWeek = @("Leistungsnachweis lesen und offene Anforderungen markieren.", "Abschluss- oder Aufgabenmaterialien mit dem aktuellen Projektstand abgleichen.", "Eine kurze Liste der fehlenden Nachweise und Artefakte erstellen.")
        nextMilestone = "Der nächste sinnvolle Meilenstein ist ein prüfbarer Zwischenstand: Prozessbeschreibung, Bewertungskriterien und offene Umsetzungsfragen müssen zusammenpassen."
        tasks = @("Bewertungskriterien mit dem Projektstand abgleichen. Quelle: $mainFact", "Materialien sichten: $($topMaterials -join ', ')", "Offene Punkte in einer eigenen Checkliste sammeln.")
        materials = $topMaterials
        risks = @("Ein Leistungsnachweis kann unvollständig wirken, wenn Bewertungskriterien nicht sichtbar im Ergebnis beantwortet werden.", "Unklare Termine oder fehlende Abgaben müssen direkt in Moodle geprüft werden.")
        nextStep = "Öffne zuerst den Leistungsnachweis oder das Bewertungsraster und markiere alle Punkte, die im aktuellen Projekt noch nicht sichtbar erfüllt sind."
    }
}

function Fill-Template {
    param([string]$Template, [hashtable]$Values)
    $result = $Template
    foreach ($key in $Values.Keys) {
        $result = $result.Replace("{{$key}}", [string]$Values[$key])
    }
    return $result
}

$projectRoot = Get-ProjectRoot
if ([string]::IsNullOrWhiteSpace($EnvPath)) { $EnvPath = Join-Path $projectRoot ".env" }
if ([string]::IsNullOrWhiteSpace($TemplatePath)) { $TemplatePath = Join-Path $projectRoot "templates\lernplan-single-course.html" }
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $projectRoot "output\manual" }
if (-not (Test-Path -LiteralPath $EnvPath)) { throw ".env nicht gefunden: $EnvPath" }
if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "Template nicht gefunden: $TemplatePath" }

$envValues = Read-EnvFile $EnvPath
$moodleApiKey = Get-EnvValue $envValues "MOODLE_API_KEY"
$geminiApiKey = Get-EnvValue $envValues "GEMINI_API_KEY"
$moodleBaseUrl = Get-EnvValue $envValues "MOODLE_BASE_URL" "https://moodle-services.os-home.net"
if ([string]::IsNullOrWhiteSpace($Model)) { $Model = Get-EnvValue $envValues "GEMINI_MODEL" "gemini-2.5-flash" }
if ([string]::IsNullOrWhiteSpace($moodleApiKey)) { throw "MOODLE_API_KEY fehlt." }
if ([string]::IsNullOrWhiteSpace($geminiApiKey)) { throw "GEMINI_API_KEY fehlt." }

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$coursesResponse = Invoke-MoodleApi -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -Path "/api/courses"
$course = Select-Course -CoursesResponse $coursesResponse -CourseId $CourseId
if ($null -eq $course) { throw "Kurs $CourseId wurde in Moodle Services nicht gefunden." }

$materialsResponse = Invoke-MoodleApi -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -Path "/api/courses/$CourseId/materials"
$materials = Get-Materials $materialsResponse
$courseName = Repair-Text $course.fullname
$courseTitle = ($courseName -replace '\s*\([^)]*\)\s*$', '').Trim()
if ([string]::IsNullOrWhiteSpace($courseTitle)) { $courseTitle = "Lernplan $Semester - Kurs $CourseId" }

$tempSourceDir = Join-Path ([System.IO.Path]::GetTempPath()) ("rpa-lernplan-sources-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempSourceDir | Out-Null
$sourceDocuments = Convert-SourceDocuments -Materials $materials -TempDir $tempSourceDir -BaseUrl $moodleBaseUrl -ApiKey $moodleApiKey -CourseId $CourseId
$assessmentFacts = Convert-AssessmentFacts -SourceDocuments $sourceDocuments

$promptInput = [pscustomobject]@{
    today = (Get-Date).ToString("yyyy-MM-dd")
    semester = $Semester
    courseId = $CourseId
    courseName = $courseTitle
    materials = @($materials | ForEach-Object {
        [pscustomobject]@{
            title = Repair-Text $_.name
            section = Repair-Text $_.sectionName
            kind = Repair-Text $(if ($_.fileType) { $_.fileType } elseif ($_.type) { $_.type } else { "Material" })
        }
    })
    sourceFacts = @($assessmentFacts | Select-Object source, text)
    sourceDocuments = @($sourceDocuments | Select-Object title, kind, section, excerpt)
}

$systemText = @"
Du füllst einen Lernplan als JSON. Schreibe Deutsch, ruhig und konkret.
Sprich die lesende Person direkt mit "du" an. Verwende nicht die formelle Sie-Form.
Erfinde keine harten Fakten zum Leistungsnachweis. Nutze dafür nur sourceFacts und sourceDocuments.
Keine Markdown-Ausgabe, keine HTML-Ausgabe, keine Erklärungen. Antworte nur mit gültigem JSON.
"@

$userText = @"
Erzeuge JSON mit exakt diesen Feldern:
situation: kurzer Absatz, muss mit "Stand: $($promptInput.today)." beginnen.
thisWeek: Array mit 2 bis 4 konkreten Arbeitsblöcken.
nextMilestone: kurzer Absatz.
tasks: Array mit 4 bis 6 Objekten. Jedes Objekt hat exakt diese Felder:
- name: kurzer Aufgabenname mit 2 bis 5 Woertern.
- description: ein knapper Satz, der sagt, was konkret zu tun ist. Maximal 150 Zeichen.
materials: Array mit 3 bis 6 wichtigen Moodle-Materialien und wofür sie benutzt werden.
risks: Array mit 2 bis 4 Risiken oder offenen Punkten.
nextStep: genau eine sofort ausführbare Handlung.

Regeln:
- Nicht wie ein Chatbot schreiben.
- In der Du-Form schreiben, nicht in der Sie-Form.
- Links nicht als Markdown formatieren.
- Keine generischen Motivationssätze.
- Wenn sourceFacts Fakten zu Gewichtung, Umfang, Prozessumfang, Bewertung oder Inhaltsstruktur enthalten, baue sie in tasks und nextMilestone ein.
- Benutze konkrete Dateinamen aus Moodle.
- Wiederhole lange Bewertungskriterien nicht in den Aufgaben. Der Bewertungsabschnitt zeigt die Details bereits.

Daten:
$($promptInput | ConvertTo-Json -Depth 30)
"@

$payload = [pscustomobject]@{
    systemInstruction = @{ parts = @(@{ text = $systemText }) }
    contents = @(@{ role = "user"; parts = @(@{ text = $userText }) })
    generationConfig = @{ temperature = 0.35; topP = 0.85; responseMimeType = "application/json" }
}

try {
    $plan = Invoke-GeminiJson -ApiKey $geminiApiKey -Model $Model -Payload $payload
} catch {
    $plan = New-FallbackPlan -CourseName $courseTitle -Facts $assessmentFacts -Materials $materials
}

$safeCourseName = ($courseTitle -replace '[^\p{L}\p{Nd}]+', '-').Trim('-')
if ($safeCourseName.Length -gt 52) { $safeCourseName = $safeCourseName.Substring(0, 52).Trim('-') }
if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $OutputDir "Lernplan_${Semester}_Kurs${CourseId}_${safeCourseName}.html"
}
$sourcesFile = [System.IO.Path]::ChangeExtension($OutputFile, ".sources.json")

$sourceHtmlItems = @($sourceDocuments | Select-Object -First 8 | ForEach-Object {
    $useText = if (-not [string]::IsNullOrWhiteSpace($_.excerpt)) { $_.excerpt } else { "als Moodle-Quelle für diesen Kurs berücksichtigt" }
    "$(ConvertTo-LinkHtml $_.url $_.title) <span class=""source"">$(ConvertTo-HtmlText $_.kind), $(ConvertTo-HtmlText $_.section): $(ConvertTo-HtmlText (Limit-Text $useText 180))</span>"
})
$materialItems = @($plan.materials | ForEach-Object { ConvertTo-HtmlText (Convert-PlanItemText $_) })

$template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8
$html = Fill-Template -Template $template -Values @{
    "TITLE" = ConvertTo-HtmlText $courseTitle
    "SEMESTER" = ConvertTo-HtmlText $Semester
    "COURSE_ID" = ConvertTo-HtmlText $CourseId
    "DATE" = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    "MATERIAL_COUNT" = $materials.Count.ToString()
    "SOURCE_COUNT" = $sourceDocuments.Count.ToString()
    "SITUATION" = ConvertTo-HtmlText $plan.situation
    "THIS_WEEK" = Convert-ItemsToHtmlList (@($plan.thisWeek | ForEach-Object { ConvertTo-HtmlText (Convert-PlanItemText $_) }))
    "NEXT_MILESTONE" = Convert-ParagraphsToHtml (Convert-PlanItemText $plan.nextMilestone)
    "ASSESSMENT_FACTS" = Convert-FactsToHtml $assessmentFacts
    "TASKS" = Convert-TasksToHtml $plan.tasks
    "MATERIALS" = Convert-ItemsToHtmlList $materialItems
    "MOODLE_SOURCES" = Convert-ItemsToHtmlList $sourceHtmlItems "links"
    "RISKS" = Convert-ItemsToHtmlList (@($plan.risks | ForEach-Object { ConvertTo-HtmlText (Convert-PlanItemText $_) }))
    "NEXT_STEP" = Convert-ParagraphsToHtml (Convert-PlanItemText $plan.nextStep)
}

Set-Content -LiteralPath $OutputFile -Value $html -Encoding UTF8
@{
    generatedAt = (Get-Date).ToString("o")
    semester = $Semester
    courseId = $CourseId
    courseTitle = $courseTitle
    outputFile = $OutputFile
    assessmentFacts = $assessmentFacts
    sourceDocuments = @($sourceDocuments | Select-Object id, title, kind, section, url, excerpt)
    plan = $plan
} | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $sourcesFile -Encoding UTF8

Write-Host "HTML-Lernplan geschrieben: $OutputFile"
Write-Host "Quellen-JSON geschrieben: $sourcesFile"

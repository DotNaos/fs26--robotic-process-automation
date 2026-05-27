param(
    [string]$OutputDir = [Environment]::GetFolderPath("MyDocuments"),
    [string]$Semester = "FS26"
)

$ErrorActionPreference = "Stop"

function Read-DotEnv {
    $envPath = $env:RPA_ENV_PATH
    if ([string]::IsNullOrWhiteSpace($envPath)) {
        $envPath = Join-Path (Get-Location) ".env"
    }

    $config = @{}
    if (-not (Test-Path -LiteralPath $envPath)) {
        return $config
    }

    foreach ($line in Get-Content -LiteralPath $envPath) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $config[$key] = $value
    }

    return $config
}

function Convert-InlineMarkdown {
    param([string]$Text)

    $escaped = [System.Net.WebUtility]::HtmlEncode($Text)
    $escaped = [regex]::Replace($escaped, '\*\*(.+?)\*\*', '<strong>$1</strong>')
    $escaped = [regex]::Replace($escaped, '\*(.+?)\*', '<em>$1</em>')
    $escaped = [regex]::Replace($escaped, '`([^`]+)`', '<code>$1</code>')
    return $escaped
}

function Convert-MarkdownToHtml {
    param([string]$Markdown)

    $builder = New-Object System.Text.StringBuilder
    $inList = $false
    $inCode = $false

    foreach ($line in ($Markdown -split "`r?`n")) {
        if ($line -match "^\s*```\s*$") {
            if ($inList) {
                [void]$builder.AppendLine("</ul>")
                $inList = $false
            }
            if ($inCode) {
                [void]$builder.AppendLine("</code></pre>")
            } else {
                [void]$builder.AppendLine("<pre><code>")
            }
            $inCode = -not $inCode
            continue
        }

        if ($inCode) {
            [void]$builder.AppendLine([System.Net.WebUtility]::HtmlEncode($line))
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($inList) {
                [void]$builder.AppendLine("</ul>")
                $inList = $false
            }
            continue
        }

        if ($line -match "^\s*###\s+(.+)$") {
            if ($inList) { [void]$builder.AppendLine("</ul>"); $inList = $false }
            [void]$builder.AppendLine("<h3>$(Convert-InlineMarkdown $Matches[1])</h3>")
        } elseif ($line -match "^\s*##\s+(.+)$") {
            if ($inList) { [void]$builder.AppendLine("</ul>"); $inList = $false }
            [void]$builder.AppendLine("<h2>$(Convert-InlineMarkdown $Matches[1])</h2>")
        } elseif ($line -match "^\s*#\s+(.+)$") {
            if ($inList) { [void]$builder.AppendLine("</ul>"); $inList = $false }
            [void]$builder.AppendLine("<h1>$(Convert-InlineMarkdown $Matches[1])</h1>")
        } elseif ($line -match "^\s*[-*]\s+(.+)$") {
            if (-not $inList) {
                [void]$builder.AppendLine("<ul>")
                $inList = $true
            }
            [void]$builder.AppendLine("<li>$(Convert-InlineMarkdown $Matches[1])</li>")
        } elseif ($line -match "^\s*\d+\.\s+(.+)$") {
            if (-not $inList) {
                [void]$builder.AppendLine("<ul>")
                $inList = $true
            }
            [void]$builder.AppendLine("<li>$(Convert-InlineMarkdown $Matches[1])</li>")
        } else {
            if ($inList) {
                [void]$builder.AppendLine("</ul>")
                $inList = $false
            }
            [void]$builder.AppendLine("<p>$(Convert-InlineMarkdown $line)</p>")
        }
    }

    if ($inList) {
        [void]$builder.AppendLine("</ul>")
    }
    if ($inCode) {
        [void]$builder.AppendLine("</code></pre>")
    }

    return $builder.ToString()
}

function Normalize-LearningPlanMarkdown {
    param([string]$Markdown)

    $Markdown = $Markdown `
        -replace 'Ãœ', 'Ü' `
        -replace 'Ã¼', 'ü' `
        -replace 'Ã¤', 'ä' `
        -replace 'Ã¶', 'ö' `
        -replace 'Ã„', 'Ä' `
        -replace 'Ã–', 'Ö' `
        -replace 'ÃŸ', 'ß'

    $lines = $Markdown -split "`r?`n"
    $clean = New-Object System.Collections.Generic.List[string]
    $skipRestOfMetaBlock = $false

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            if ($clean.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($clean[$clean.Count - 1])) {
                $clean.Add("")
            }
            continue
        }

        $isMeta = $false
        $metaPatterns = @(
            '^(Lerncoach|Learning Coach)\.?$',
            '^(Markdown|German|Deutsch)\.?$',
            '^German Learning Coach',
            '^Final learning plan',
            '^Final Learning Plan',
            '^Only the final plan',
            '^German section titles',
            '^H1 header',
            '^Exactly one H1',
            '^If data is missing',
            '^Must start exactly',
            '^Finished learning plan',
            '^Completed Learning Plan',
            '^Must start with',
            '^Start directly with',
            '^No analysis',
            '^No meta',
            '^No internal',
            '^No JSON',
            '^No code',
            '^No English',
            '^Overview[, ]',
            '^Overview \(',
            '^Use "Annahmen"',
            '^Mention short assumptions',
            '^Course materials',
            '^Ensure no',
            '^Start exactly',
            '^Markdown formatting',
            '^\*\s+\*Constraint Check:\*',
            '^\*\s+Wait,',
            '^\*\s+Must be Markdown',
            '^\*\s+No code blocks',
            '^\*\s+Direct start with',
            '^\*\s+No repetition',
            '^\*\s+Only German section titles',
            '^\*\s+Start with exactly one H1',
            '^\*\s+Followed by H2 sections',
            '^\*\s+If data is missing',
            '^\*\s+Check against constraints',
            '^\*\s+Assumptions \(Annahmen\)',
            '^\*\s+Overview \(Überblick\)',
            '^\*\s+Learning Goals \(Lernziele\)',
            '^\*\s+Weekly Plan \(Wochenplan\)',
            '^\*\s+Materials \(Materialien\)',
            '^\*\s+Exam Preparation \(Prüfungsvorbereitung\)',
            '^\*\s+Next Steps \(Nächste Schritte\)'
        )

        foreach ($pattern in $metaPatterns) {
            if ($trimmed -match $pattern) {
                $isMeta = $true
                break
            }
        }

        if ($isMeta) {
            continue
        }

        $line = $line -replace '^\s*\*\s+\*Overview:\*\s*', ("## Überblick" + "`n")
        $line = $line -replace '^\s*\*\s+\*Learning (Goals|Objectives):\*\s*', ("## Lernziele" + "`n")
        $line = $line -replace '^\s*\*\s+\*Weekly Plan:\*\s*', ("## Wochenplan" + "`n")
        $line = $line -replace '^\s*\*\s+\*Materials:\*\s*', ("## Materialien" + "`n")
        $line = $line -replace '^\s*\*\s+\*Exam Prep(aration)?:\*\s*', ("## Prüfungsvorbereitung" + "`n")
        $line = $line -replace '^\s*\*\s+\*Next Steps:\*\s*', ("## Nächste Schritte" + "`n")
        $line = $line -replace '^\s*\*\s+\*Annahmen:\*\s*', ("## Annahmen" + "`n")
        $line = $line -replace '^\s*\*\s+\*Course Theme:\*\s*', ("## Überblick" + "`n")
        $line = $line -replace '^\s*\*\s+\*Key Topics:\*\s*', ("## Lernziele" + "`n")
        $line = $line -replace '^\s*\*\s+\*Timeframe:\*\s*', ("## Wochenplan" + "`n")

        $clean.Add($line.TrimEnd())
    }

    $result = ($clean -join "`n").Trim()
    if ($result -notmatch '(?m)^##\s+') {
        $firstBlank = $result.IndexOf("`n`n")
        if ($firstBlank -gt 0) {
            $title = $result.Substring(0, $firstBlank).Trim()
            $rest = $result.Substring($firstBlank).Trim()
            $result = "$title`n`n## Überblick`n$rest"
        }
    }

    return $result + "`n"
}

function New-FullHtmlDocument {
    param(
        [string]$Title,
        [string]$Body
    )

    $safeTitle = [System.Net.WebUtility]::HtmlEncode($Title)
    return @"
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>$safeTitle</title>
  <style>
    body { font-family: "Segoe UI", Arial, sans-serif; color: #1f2933; line-height: 1.55; margin: 40px; }
    h1 { color: #17324d; font-size: 28px; margin: 0 0 20px; }
    h2 { color: #24506f; border-bottom: 1px solid #d9e2ec; font-size: 21px; margin-top: 28px; padding-bottom: 6px; }
    h3 { color: #334e68; font-size: 17px; margin-top: 22px; }
    p { margin: 8px 0 12px; }
    ul { margin: 8px 0 16px 24px; padding: 0; }
    li { margin: 5px 0; }
    code { background: #eef2f7; border-radius: 4px; padding: 1px 4px; }
    pre { background: #f5f7fa; border: 1px solid #d9e2ec; border-radius: 6px; padding: 12px; white-space: pre-wrap; }
    .plan { page-break-after: always; }
    .plan:last-child { page-break-after: auto; }
    .intro { color: #52606d; margin-bottom: 24px; }
  </style>
</head>
<body>
$Body
</body>
</html>
"@
}

function Find-Browser {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
        (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Google\Chrome\Application\chrome.exe")
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    throw "Kein Edge/Chrome Browser fuer die PDF-Erzeugung gefunden."
}

function Convert-HtmlToPdf {
    param(
        [string]$HtmlPath,
        [string]$PdfPath,
        [string]$BrowserPath
    )

    if (Test-Path -LiteralPath $PdfPath) {
        Remove-Item -LiteralPath $PdfPath -Force
    }

    $htmlUri = ([Uri](Resolve-Path -LiteralPath $HtmlPath).Path).AbsoluteUri
    $args = @("--headless=new", "--disable-gpu", "--disable-extensions", "--disable-default-apps", "--no-first-run", "--no-default-browser-check", "--print-to-pdf=$PdfPath", $htmlUri)
    $process = Start-Process -FilePath $BrowserPath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden

    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $PdfPath)) {
        throw "PDF-Erzeugung fehlgeschlagen: $PdfPath"
    }
}

$config = Read-DotEnv
$outputPath = [System.IO.Path]::GetFullPath($OutputDir)
if (-not (Test-Path -LiteralPath $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$plans = Get-ChildItem -LiteralPath $outputPath -Filter "Lernplan_${Semester}_Kurs*.html" | Sort-Object Name
if ($plans.Count -eq 0) {
    throw "Keine HTML-Lernplaene gefunden in $outputPath."
}

$browser = Find-Browser
$renderedPlans = @()
$attachments = @()

foreach ($plan in $plans) {
    $fullHtml = Get-Content -LiteralPath $plan.FullName -Raw -Encoding UTF8
    $htmlPath = $plan.FullName
    $pdfPath = [System.IO.Path]::ChangeExtension($plan.FullName, ".pdf")
    Convert-HtmlToPdf -HtmlPath $htmlPath -PdfPath $pdfPath -BrowserPath $browser

    $bodyMatch = [regex]::Match($fullHtml, '(?is)<main\b[^>]*>(?<body>.*)</main>')
    if ($bodyMatch.Success) {
        $renderedPlans += "<article class=`"plan`">$($bodyMatch.Groups["body"].Value)</article>"
    } else {
        $renderedPlans += "<article class=`"plan`">$fullHtml</article>"
    }
    $attachments += $pdfPath
}

$sendEmail = $config.ContainsKey("SEND_EMAIL") -and $config["SEND_EMAIL"].Trim().ToLowerInvariant() -eq "true"
if (-not $sendEmail) {
    Write-Host "PDFs gerendert. E-Mail Versand uebersprungen, weil SEND_EMAIL nicht true ist."
    exit 0
}

if (-not $config.ContainsKey("RECIPIENT_EMAIL") -or [string]::IsNullOrWhiteSpace($config["RECIPIENT_EMAIL"])) {
    throw "SEND_EMAIL=true, aber RECIPIENT_EMAIL fehlt in der .env."
}

$smtpHost = "smtp.gmail.com"
if ($config.ContainsKey("SMTP_HOST") -and -not [string]::IsNullOrWhiteSpace($config["SMTP_HOST"])) {
    $smtpHost = $config["SMTP_HOST"].Trim()
}

$smtpPort = 587
if ($config.ContainsKey("SMTP_PORT") -and -not [string]::IsNullOrWhiteSpace($config["SMTP_PORT"])) {
    $smtpPort = [int]$config["SMTP_PORT"]
}

$smtpEnableSsl = $smtpHost -eq "smtp.gmail.com"
if ($config.ContainsKey("SMTP_ENABLE_SSL") -and -not [string]::IsNullOrWhiteSpace($config["SMTP_ENABLE_SSL"])) {
    $smtpEnableSsl = $config["SMTP_ENABLE_SSL"].Trim().ToLowerInvariant() -in @("1", "true", "yes", "on")
}

$smtpUsername = ""
if ($config.ContainsKey("SMTP_USERNAME") -and -not [string]::IsNullOrWhiteSpace($config["SMTP_USERNAME"])) {
    $smtpUsername = $config["SMTP_USERNAME"].Trim()
} elseif ($config.ContainsKey("GMAIL_ADDRESS") -and -not [string]::IsNullOrWhiteSpace($config["GMAIL_ADDRESS"])) {
    $smtpUsername = $config["GMAIL_ADDRESS"].Trim()
}

$smtpPassword = ""
if ($config.ContainsKey("SMTP_PASSWORD") -and -not [string]::IsNullOrWhiteSpace($config["SMTP_PASSWORD"])) {
    $smtpPassword = $config["SMTP_PASSWORD"]
} elseif ($config.ContainsKey("GMAIL_APP_PASSWORD") -and -not [string]::IsNullOrWhiteSpace($config["GMAIL_APP_PASSWORD"])) {
    $smtpPassword = $config["GMAIL_APP_PASSWORD"]
}

if ($smtpHost -eq "smtp.gmail.com" -and ([string]::IsNullOrWhiteSpace($smtpUsername) -or [string]::IsNullOrWhiteSpace($smtpPassword))) {
    throw "SEND_EMAIL=true mit Gmail SMTP benoetigt GMAIL_ADDRESS und GMAIL_APP_PASSWORD oder SMTP_USERNAME und SMTP_PASSWORD."
}

$from = $config["SMTP_FROM_ADDRESS"]
if ([string]::IsNullOrWhiteSpace($from)) {
    if (-not [string]::IsNullOrWhiteSpace($smtpUsername) -and $smtpUsername.ToLowerInvariant().EndsWith("@gmail.com")) {
        $from = $smtpUsername -replace "@gmail\.com$", "+uipath-moodle@gmail.com"
    } elseif (-not [string]::IsNullOrWhiteSpace($smtpUsername) -and $smtpUsername.Contains("@")) {
        $from = $smtpUsername
    } else {
        $from = "uipath-moodle@localhost"
    }
}

$body = New-FullHtmlDocument -Title "Lernplaene $Semester" -Body @"
<h1>Lernplaene $Semester</h1>
<p class="intro">Die generierten Lernplaene sind unten direkt lesbar. Die PDFs sind zusaetzlich als Anhang beigefuegt.</p>
$($renderedPlans -join "`n")
"@

$message = New-Object System.Net.Mail.MailMessage
$client = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
try {
    $message.From = $from
    $message.To.Add($config["RECIPIENT_EMAIL"])
    $message.Subject = "Lernplaene $Semester"
    $message.Body = $body
    $message.IsBodyHtml = $true

    foreach ($attachment in $attachments) {
        $message.Attachments.Add((New-Object System.Net.Mail.Attachment($attachment))) | Out-Null
    }

    $client.EnableSsl = $smtpEnableSsl
    if (-not [string]::IsNullOrWhiteSpace($smtpUsername) -and -not [string]::IsNullOrWhiteSpace($smtpPassword)) {
        $client.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, ($smtpPassword -replace "\s+", ""))
    }
    $client.Send($message)
    Write-Host "E-Mail mit HTML-Body und PDF-Anhaengen ueber $smtpHost`:$smtpPort gesendet an $($config["RECIPIENT_EMAIL"])."
} finally {
    $message.Dispose()
    $client.Dispose()
}

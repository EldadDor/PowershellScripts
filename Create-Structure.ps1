[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputFile,

    [Parameter(Mandatory=$false)]
    [string]$RootPath = "."
)

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

# Read as UTF-8 so ├ └ │ ─ are interpreted correctly (avoids â”œâ”€â”€ mojibake)
$lines = Get-Content -LiteralPath $InputFile -Encoding utf8

# Regex for: [indent made of "│   " or "    "]* + ("├── " or "└── ") + name
# (tree glyphs expressed as unicode escapes so this script file can remain ASCII-safe)
$branchRegex = '^(?<indent>(?:\u2502   |    )*)(?:\u251C\u2500\u2500 |\u2514\u2500\u2500 )(?<name>.+?)\s*$'

$stack = New-Object System.Collections.Generic.List[string]

function Strip-Comment([string]$s) {
    return (($s -split '#', 2)[0]).TrimEnd()
}

foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    $line2 = Strip-Comment $line
    if ([string]::IsNullOrWhiteSpace($line2)) { continue }

    # Skip connector-only lines like "│   │   │   │" from your file [[11]]
    $probe = $line2 -replace '[\s\u2502\u251C\u2514\u2500]+', ''
    if ($probe -eq '') { continue }

    $depth = 0
    $nameRaw = $null

    if ($line2 -match '[\u251C\u2514]\u2500\u2500') {
        $m = [regex]::Match($line2, $branchRegex)
        if (-not $m.Success) { continue }

        $depth = [int]($m.Groups['indent'].Value.Length / 4) + 1
        $nameRaw = $m.Groups['name'].Value.Trim()
    } else {
        # Root line like "password-manager-android/" [[11]]
        $depth = 0
        $nameRaw = $line2.Trim()
    }

    if ($nameRaw -in @('', '...', '…')) { continue }

    $isDir = $nameRaw.EndsWith('/')
    $name = $nameRaw.TrimEnd('/')
    $nameFs = $name -replace '/', '\'

    # parent depth is depth-1 (root children have parentDepth 0)
    $parentDepth = [Math]::Max(0, $depth - 1)

    while ($stack.Count -gt $parentDepth) {
        $stack.RemoveAt($stack.Count - 1)
    }

    $basePath = $RootPath
    foreach ($seg in $stack) {
        $basePath = Join-Path -Path $basePath -ChildPath $seg
    }

    $targetPath = Join-Path -Path $basePath -ChildPath $nameFs

    if ($isDir) {
        if ($PSCmdlet.ShouldProcess($targetPath, "Create directory")) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
        $stack.Add($nameFs)
    }
    else {
        $parent = Split-Path -Path $targetPath -Parent
        if ($PSCmdlet.ShouldProcess($targetPath, "Create file")) {
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $targetPath)) {
                New-Item -ItemType File -Path $targetPath -Force | Out-Null
            }
        }
    }
}

Write-Host "Structure created successfully!" -ForegroundColor Yellow

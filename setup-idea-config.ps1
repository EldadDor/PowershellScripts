# setup-idea-config.ps1

Write-Host "=== IntelliJ IDEA Config Setup ===" -ForegroundColor Cyan

# Interactive config version selection
Write-Host "`nSelect Config version to use:" -ForegroundColor Cyan
Write-Host "1: 2024 Config" -ForegroundColor Magenta
Write-Host "2: 2025 Config" -ForegroundColor Magenta

do {
    $configSelection = Read-Host "Enter your choice (1 or 2)"
    $isValidConfig = ($configSelection -eq "1") -or ($configSelection -eq "2")
    if (-not $isValidConfig) {
        Write-Host "Invalid selection. Please enter 1 or 2." -ForegroundColor Red
    }
} until ($isValidConfig)

# Set config paths based on selection
if ($configSelection -eq "1") {
    $ConfigPath = "C:\config\IntelliJIdea-2024"
    $ConfigVersion = "2024"
} else {
    $ConfigPath = "C:\config\IntelliJIdea-2025"
    $ConfigVersion = "2025"
}

Write-Host "Selected config version: $ConfigVersion" -ForegroundColor Green

$RepoUrl = "https://IDI-Insurance@dev.azure.com/IDI-Insurance/DevopsScripts/_git/IntelliJIdeaConfig-Repo"

if (Test-Path $ConfigPath) {
    Write-Host "Config folder exists. Pulling latest..." -ForegroundColor Yellow
    Push-Location $ConfigPath
    git pull
    Pop-Location
} else {
    Write-Host "Config folder not found. Cloning repository..." -ForegroundColor Green
    git clone $RepoUrl $ConfigPath
}

# Interactive IntelliJ installation version selection
Write-Host "`nSelect IntelliJ installation version for source files:" -ForegroundColor Cyan
Write-Host "1: 2024 Installation" -ForegroundColor Magenta
Write-Host "2: 2025 Installation" -ForegroundColor Magenta

do {
    $installSelection = Read-Host "Enter your choice (1 or 2)"
    $isValidInstall = ($installSelection -eq "1") -or ($installSelection -eq "2")
    if (-not $isValidInstall) {
        Write-Host "Invalid selection. Please enter 1 or 2." -ForegroundColor Red
    }
} until ($isValidInstall)

# Set source paths based on installation selection
if ($installSelection -eq "1") {
    $SourcePath = "J:\INSTALL-TOOLS\TOOLS\Intellij\2024\conf\idea.properties"
    $VmOptionsPath = "J:\INSTALL-TOOLS\TOOLS\Intellij\2024\conf\idea64.exe.vmoptions"
    $InstallVersion = "2024"
} else {
    $SourcePath = "J:\INSTALL-TOOLS\TOOLS\Intellij\2025\conf\idea.properties"
    $VmOptionsPath = "J:\INSTALL-TOOLS\TOOLS\Intellij\2025\conf\idea64.exe.vmoptions"
    $InstallVersion = "2025"
}

Write-Host "Selected installation version: $InstallVersion" -ForegroundColor Green
Write-Host "Using $ConfigVersion config with $InstallVersion installation files" -ForegroundColor Yellow

Write-Host "`nAvailable JetBrains folders:" -ForegroundColor Cyan
$jetbrainsRoot = "C:\Program Files\JetBrains\"
$folders = Get-ChildItem -Path $jetbrainsRoot -Directory | Select-Object -ExpandProperty Name

for ($i = 0; $i -lt $folders.Count; $i++) {
    Write-Host "$($i+1): $($folders[$i])" -ForegroundColor Magenta
}

do {
    $selection = Read-Host "Enter the number of the folder to copy config files to"
    $isValid = ($selection -as [int]) -and ($selection -ge 1) -and ($selection -le $folders.Count)
    if (-not $isValid) {
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    }
} until ($isValid)

$targetFolder = Join-Path $jetbrainsRoot $folders[$selection - 1]
$binPath = Join-Path $targetFolder "bin"

Write-Host "Copying files to $binPath..." -ForegroundColor Yellow

Copy-Item $SourcePath (Join-Path $binPath "idea.properties") -Force
# Uncomment if needed:
# Copy-Item $VmOptionsPath (Join-Path $binPath "idea64.exe.vmoptions") -Force

Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host "Config version: $ConfigVersion | Installation version: $InstallVersion" -ForegroundColor Cyan

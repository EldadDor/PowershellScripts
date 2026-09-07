[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({
        if (Test-Path $_ -PathType Container) {
            $true
        } else {
            throw "Path '$_' does not exist or is not a directory."
        }
    })]
    [string]$FolderPath,

    [Parameter(Mandatory=$false)]
    [Alias("Exclude")]
    [string[]]$ExcludeFolders = @(),

    [Parameter(Mandatory=$false)]
    [Alias("Depth")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MaxDepth = [int]::MaxValue,

    [Parameter(Mandatory=$false)]
    [switch]$ShowDepth,

    [Parameter(Mandatory=$false)]
    [switch]$AsciiOnly
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:DirCount = 0

if ($AsciiOnly) {
    $script:CharCorner = "+"
    $script:CharTee    = "+"
    $script:CharDash   = "-"
    $script:CharPipe   = "|"
} else {
    $script:CharCorner = [char]0x2514  # └
    $script:CharTee    = [char]0x251C  # ├
    $script:CharDash   = [char]0x2500  # ─
    $script:CharPipe   = [char]0x2502  # │
}

function Show-DirectoryTree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Prefix = "",
        [bool]$IsLast = $true,
        [string[]]$Exclusions = @(),
        [int]$MaxDepth = [int]::MaxValue,
        [int]$CurrentDepth = 0,
        [bool]$ShowDepth = $false
    )
    
    $dirName = Split-Path $Path -Leaf
    $depthLabel = if ($ShowDepth) { " [depth $CurrentDepth]" } else { "" }
    
    if ($CurrentDepth -eq 0) {
        Write-Host "$dirName$depthLabel" -ForegroundColor Green
    } else {
        $branch = if ($IsLast) { "$script:CharCorner$script:CharDash$script:CharDash " } else { "$script:CharTee$script:CharDash$script:CharDash " }
        Write-Host "$Prefix$branch$dirName$depthLabel" -ForegroundColor Cyan
    }
    
    $script:DirCount++
    
    if ($CurrentDepth -ge $MaxDepth) {
        return
    }
    
    try {
        $subdirectories = Get-ChildItem -Path $Path -Directory -ErrorAction Stop |
            Where-Object { $Exclusions.Count -eq 0 -or $_.Name -notin $Exclusions } |
            Sort-Object Name
        
        if ($subdirectories -and $subdirectories.Count -gt 0) {
            for ($i = 0; $i -lt $subdirectories.Count; $i++) {
                $isLastSubdir = ($i -eq ($subdirectories.Count - 1))
                
                if ($CurrentDepth -eq 0) {
                    $newPrefix = ""
                } else {
                    $newPrefix = $Prefix + $(if ($IsLast) { "    " } else { "$script:CharPipe   " })
                }
                
                Show-DirectoryTree -Path $subdirectories[$i].FullName -Prefix $newPrefix -IsLast $isLastSubdir -Exclusions $Exclusions -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1) -ShowDepth $ShowDepth
            }
        }
    }
    catch {
        Write-Warning "Cannot access subdirectories in '$Path': $($_.Exception.Message)"
    }
}

$FolderPath = Resolve-Path $FolderPath -ErrorAction Stop

Write-Host "`nDirectory Tree Structure for: $FolderPath" -ForegroundColor Yellow
if ($ExcludeFolders.Count -gt 0) {
    Write-Host "Excluding folders: $($ExcludeFolders -join ', ')" -ForegroundColor DarkYellow
}
if ($MaxDepth -ne [int]::MaxValue) {
    Write-Host "Max depth: $MaxDepth" -ForegroundColor DarkYellow
}
Write-Host ("=" * 50) -ForegroundColor Yellow
Show-DirectoryTree -Path $FolderPath -Exclusions $ExcludeFolders -MaxDepth $MaxDepth -ShowDepth $ShowDepth

Write-Host "`n$($script:DirCount) directories" -ForegroundColor Yellow
Write-Host ""

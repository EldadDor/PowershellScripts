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
    [string]$FolderPath
)

function Show-DirectoryTree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Prefix = "",
        [bool]$IsLast = $true
    )
    
    # Get the directory name
    $dirName = Split-Path $Path -Leaf
    
    # Create the tree symbols using standard ASCII characters
    if ($Prefix -eq "") {
        # Root directory
        Write-Host $dirName -ForegroundColor Green
    } else {
        # Subdirectory
        $symbol = if ($IsLast) { "+-- " } else { "+-- " }
        Write-Host "$Prefix$symbol$dirName" -ForegroundColor Cyan
    }
    
    # Get all subdirectories
    try {
        $subdirectories = Get-ChildItem -Path $Path -Directory -ErrorAction Stop | Sort-Object Name
        
        if ($subdirectories -and $subdirectories.Count -gt 0) {
            for ($i = 0; $i -lt $subdirectories.Count; $i++) {
                $isLastSubdir = ($i -eq ($subdirectories.Count - 1))
                
                # Create new prefix for subdirectories
                if ($Prefix -eq "") {
                    $newPrefix = ""
                } else {
                    $newPrefix = $Prefix + $(if ($IsLast) { "    " } else { "|   " })
                }
                
                # Recursively call for each subdirectory
                Show-DirectoryTree -Path $subdirectories[$i].FullName -Prefix $newPrefix -IsLast $isLastSubdir
            }
        }
    }
    catch {
        Write-Warning "Cannot access subdirectories in '$Path': $($_.Exception.Message)"
    }
}

# Convert relative path to absolute path
$FolderPath = Resolve-Path $FolderPath -ErrorAction Stop

Write-Host "`nDirectory Tree Structure for: $FolderPath" -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Yellow
Show-DirectoryTree -Path $FolderPath
Write-Host ""

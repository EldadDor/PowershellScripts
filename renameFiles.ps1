function Restore-FilesWithOriginalExtension {
    param(
        [string]$Path = ".",
        [string[]]$FileExtensions = @("xml", "icls", "js","ini","groovy","toml","yml","yaml","ts", "tsx", "java", "py", "bat", "css", "html","json"),
        [string]$LogFile = "restore_rename_log.txt"
    )

    $extPattern = ($FileExtensions -join '|')
    $regex = "^(?<basename>.+)_(?<ext>$extPattern)\.txt$"

    Get-ChildItem -Path $Path -Recurse -File -Filter "*.txt" | ForEach-Object {
        if ($_.Name -match $regex) {
            $baseName = $matches['basename']
            $ext = $matches['ext']
            $dir = $_.DirectoryName
            $newName = "$baseName.$ext"
            $newPath = Join-Path $dir $newName

            try {
                Rename-Item -Path $_.FullName -NewName $newPath -ErrorAction Stop
                $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] SUCCESS: '$($_.FullName)' renamed to '$newPath'"
                Write-Host $logMsg -ForegroundColor Green
                Add-Content -Path $LogFile -Value $logMsg
            }
            catch {
                $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: Failed to rename '$($_.FullName)' to '$newPath' - $($_.Exception.Message)"
                Write-Host $logMsg -ForegroundColor Red
                Add-Content -Path $LogFile -Value $logMsg
            }
        }
    }
}


function Rename-FilesWithExtension {
    param(
        [string]$Path = ".",
        [string[]]$FileExtensions = @("xml", "icls", "js","ini","groovy","toml","yml","yaml","ts", "tsx", "java", "py", "bat", "css", "html","json")
    )
    
    # Create the include pattern for Get-ChildItem
    $includePatterns = $FileExtensions | ForEach-Object { "*.$_" }
    
    Get-ChildItem -Path $Path -Recurse -File -Include $includePatterns | ForEach-Object {
        $dir = $_.DirectoryName
        $baseName = $_.BaseName
        $ext = $_.Extension.TrimStart('.')
        $newName = "${baseName}_$ext.txt"
        $newPath = Join-Path $dir $newName
        Rename-Item -Path $_.FullName -NewName $newPath
    }
} 
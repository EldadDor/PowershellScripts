param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "Source folder does not exist: $_"
        }
        return $true
    })]
    [string]$SourceFolder,

    [int]$MaxChunkSizeBytes = 20KB,

    [bool]$Recurse = $true
)

# Get files
$files = Get-ChildItem -Path $SourceFolder -File -Recurse:$Recurse

if ($files.Count -eq 0) {
    throw "No files found in the specified folder."
}

# Group files by extension
$fileGroups = $files | Group-Object Extension

Write-Host "Found $($fileGroups.Count) extension group(s): $($fileGroups.Name -join ', ')"
Write-Host ""

$totalOutputFiles = 0

foreach ($group in $fileGroups) {

    $extension = $group.Name.TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($extension)) {
        Write-Host "⚠️  Skipping files with no extension ($($group.Count) file(s))."
        continue
    }

    Write-Host "Processing .$extension files ($($group.Count) file(s))..."

    # Output setup per extension
    $outputIndex = 1
    $currentSize = 0
    $outputFile  = Join-Path $SourceFolder "merged_code_${extension}_$outputIndex.txt"

    New-Item -ItemType File -Path $outputFile -Force | Out-Null

    foreach ($file in ($group.Group | Sort-Object FullName)) {

        $content = Get-Content $file.FullName -Raw

        $separator = @"
============================================================
BEGIN FILE
Path: $($file.FullName)
Language: $extension
============================================================

"@

        $footer = @"

============================================================
END FILE
============================================================


"@

        $block = $separator + $content + $footer
        $blockSize = [Text.Encoding]::UTF8.GetByteCount($block)

        if (($currentSize + $blockSize) -gt $MaxChunkSizeBytes) {
            $outputIndex++
            $currentSize = 0
            $outputFile = Join-Path $SourceFolder "merged_code_${extension}_$outputIndex.txt"
            New-Item -ItemType File -Path $outputFile -Force | Out-Null
        }

        Add-Content -Path $outputFile -Value $block -Encoding UTF8
        $currentSize += $blockSize
    }

    Write-Host "   ✅ Created $outputIndex output file(s) for .$extension"
    $totalOutputFiles += $outputIndex
}

Write-Host ""
Write-Host "✅ Completed. Created $totalOutputFiles total output file(s) across $($fileGroups.Count) extension(s)."

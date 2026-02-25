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

    [bool]$Recurse = $true,

    [string]$BreadcrumbSeparator = "_"
)

# Normalize source folder path
$SourceFolder = (Resolve-Path $SourceFolder).Path.TrimEnd('\', '/')

# Get files
$files = Get-ChildItem -Path $SourceFolder -File -Recurse:$Recurse

if ($files.Count -eq 0) {
    throw "No files found in the specified folder."
}

# Output folder for merged files
$outputFolder = Join-Path $SourceFolder "_merged_output"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

# Group files by Extension + Relative Directory
$fileGroups = $files | Group-Object {
    $relDir = $_.DirectoryName.Substring($SourceFolder.Length).TrimStart('\', '/')
    "$($_.Extension)|$relDir"
}

Write-Host "Found $($fileGroups.Count) group(s) (by extension + folder)."
Write-Host ""

$totalOutputFiles = 0

foreach ($group in $fileGroups) {

    # Split the group key back into extension and relative directory
    $parts      = $group.Name -split '\|', 2
    $extension  = $parts[0].TrimStart('.')
    $relativeDir = if ($parts.Length -gt 1) { $parts[1] } else { "" }

    if ([string]::IsNullOrWhiteSpace($extension)) {
        Write-Host "⚠️  Skipping $($group.Count) file(s) with no extension in '$relativeDir'."
        continue
    }

    # Build breadcrumb string from relative folder path
    if ([string]::IsNullOrWhiteSpace($relativeDir)) {
        $breadcrumb = "root"
    }
    else {
        # Replace path separators with the breadcrumb separator
        $breadcrumb = $relativeDir -replace '[\\\/]', $BreadcrumbSeparator
        # Sanitize: remove any characters that are invalid in file names
        $breadcrumb = $breadcrumb -replace '[^\w\-\.]', $BreadcrumbSeparator
        # Collapse multiple consecutive separators
        $breadcrumb = $breadcrumb -replace "($([regex]::Escape($BreadcrumbSeparator))){2,}", $BreadcrumbSeparator
        $breadcrumb = $breadcrumb.Trim($BreadcrumbSeparator)
    }

    Write-Host "Processing .$extension files | Folder: $( if ($relativeDir) { $relativeDir } else { '(root)' } ) | $($group.Count) file(s)..."

    # Output setup per group
    $outputIndex = 1
    $currentSize = 0
    $outputFile  = Join-Path $outputFolder "merged_${breadcrumb}_${extension}_$outputIndex.txt"

    New-Item -ItemType File -Path $outputFile -Force | Out-Null

    foreach ($file in ($group.Group | Sort-Object FullName)) {

        $content = Get-Content $file.FullName -Raw

        # Relative path of the file from source for readability in the header
        $relFilePath = $file.FullName.Substring($SourceFolder.Length).TrimStart('\', '/')

        $separator = @"
============================================================
BEGIN FILE
Path: $relFilePath
Language: $extension
============================================================

"@

        $footer = @"

============================================================
END FILE
============================================================


"@

        $block     = $separator + $content + $footer
        $blockSize = [Text.Encoding]::UTF8.GetByteCount($block)

        if (($currentSize + $blockSize) -gt $MaxChunkSizeBytes) {
            $outputIndex++
            $currentSize = 0
            $outputFile = Join-Path $outputFolder "merged_${breadcrumb}_${extension}_$outputIndex.txt"
            New-Item -ItemType File -Path $outputFile -Force | Out-Null
        }

        Add-Content -Path $outputFile -Value $block -Encoding UTF8
        $currentSize += $blockSize
    }

    Write-Host "   ✅ Created $outputIndex file(s) → merged_${breadcrumb}_${extension}_*.txt"
    $totalOutputFiles += $outputIndex
}

Write-Host ""
Write-Host "✅ Completed. Created $totalOutputFiles total output file(s) in: $outputFolder"

param(
  [string]$Path = ".",
  [int]$Depth = 50,
  [string[]]$Exclude = @("node_modules")
)

function Show-Tree([string]$P, [string]$Prefix, [int]$D) {
  if ($D -le 0) { return }

  $items = Get-ChildItem -LiteralPath $P -Force |
    Where-Object { $Exclude -notcontains $_.Name } |
    Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name

  for ($i = 0; $i -lt $items.Count; $i++) {
    $isLast = ($i -eq $items.Count - 1)
    $conn   = if ($isLast) { "\-- " } else { "+-- " }

    Write-Output ("{0}{1}{2}" -f $Prefix, $conn, $items[$i].Name)

    if ($items[$i].PSIsContainer) {
      $nextPrefix = $Prefix + $(if ($isLast) { "    " } else { "|   " })
      Show-Tree -P $items[$i].FullName -Prefix $nextPrefix -D ($D - 1)
    }
  }
}

Show-Tree -P (Resolve-Path $Path) -Prefix "" -D $Depth
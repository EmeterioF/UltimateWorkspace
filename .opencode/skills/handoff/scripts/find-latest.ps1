<#
  find-latest.ps1 - print the handoff a fresh session should restore.

  Prints one path. Newest first among the last $Scan files, taking the
  first with `state: open`. Falls back to the newest file and says so.

  Exit 2 means "nothing here" - stop and ask the user.
#>
[CmdletBinding()]
param(
  [string]$Directory = 'memory',
  [int]$Scan = 5
)

$files = @(Get-ChildItem $Directory -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}-\d{3}\.md$' } |
  Sort-Object Name)

if ($files.Count -eq 0) {
  $any = @(Get-ChildItem $Directory -File -Filter '*.md' -ErrorAction SilentlyContinue)
  if ($any.Count -gt 0) {
    Write-Output 'No handoff files match YYYY-MM-DD-NNN.md, but the directory has:'
    $any.Name | ForEach-Object { Write-Output "  $_" }
    Write-Output 'Stop here and ask the user. Do not guess which file is the handoff.'
  } else {
    Write-Output "$Directory is empty. Nothing to restore."
  }
  exit 2
}

$recent = @($files | Select-Object -Last $Scan)
[array]::Reverse($recent)

$open = $recent | Where-Object {
  (Get-Content $_.FullName -TotalCount 10) -match '^state:\s*open'
} | Select-Object -First 1

if ($open) {
  Write-Output $open.FullName
  exit 0
}

Write-Output 'no open thread - newest handoff is closed'
Write-Output $files[-1].FullName
exit 0

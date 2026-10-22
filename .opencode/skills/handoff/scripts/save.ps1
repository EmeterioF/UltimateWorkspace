<#
  save.ps1 - write a handoff to memory/YYYY-MM-DD-NNN.md

  Owns the parts a model should not retype: the sequence number, the
  encoding, and the checks. A handoff that fails a check is never left
  on disk.

  Usage:
    $file = & ./scripts/save.ps1 -Content $handoff
    $file = & ./scripts/save.ps1 -ContentFile "$env:TEMP\handoff-draft.md"
#>
[CmdletBinding(DefaultParameterSetName = 'Text')]
param(
  [Parameter(Mandatory = $true, ParameterSetName = 'Text')]
  [string]$Content,

  [Parameter(Mandatory = $true, ParameterSetName = 'File')]
  [string]$ContentFile,

  [string]$Directory = 'memory'
)

$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'File') {
  if (-not (Test-Path $ContentFile)) { throw "draft not found: $ContentFile" }
  $Content = Get-Content $ContentFile -Raw
}

if ([string]::IsNullOrWhiteSpace($Content)) { throw 'handoff is empty - nothing to save' }

foreach ($f in @('state:', 'next:', 'session:', 'project:', 'changed:')) {
  if ($Content -notmatch ('(?m)^' + [regex]::Escape($f) + '\s*\S')) {
    throw "missing or empty field: $f"
  }
}

# The target directory is the one thing the next session acts on first.
$projectLine = [regex]::Match($Content, '(?m)^project:\s*(\S.*)$').Groups[1].Value.Trim()
if ($projectLine -notmatch '^[A-Za-z]:/|^/') {
  throw "project: must be an absolute path with forward slashes, got: $projectLine"
}
if (-not (Test-Path $projectLine)) {
  Write-Warning "project: $projectLine does not exist on disk - the next session will have to ask"
}

# New handoffs use `## Dead ends and traps`. verify-anchors also accepts the
# short `## Dead ends` so handoffs written before the rename still load.
foreach ($s in @('Where we are', 'Open threads', 'Decisions', 'Bugs fixed', 'Dead ends and traps', 'Verify', 'Suggested skills')) {
  if ($Content -notmatch ('(?m)^## ' + [regex]::Escape($s) + '\s*$')) {
    throw "missing section: ## $s"
  }
}

if ($Content -match '(?m)^next:\s*<') { throw 'next: still contains the template placeholder' }

if (-not (Test-Path $Directory)) { New-Item -ItemType Directory -Path $Directory | Out-Null }

$dirPath = if ([IO.Path]::IsPathRooted($Directory)) { $Directory } else { Join-Path (Get-Location) $Directory }

$today = Get-Date -Format 'yyyy-MM-dd'
$existing = @(Get-ChildItem $dirPath -File |
  Where-Object { $_.Name -match "^$today-(\d{3})\.md$" } |
  Sort-Object Name)

$next = if ($existing.Count -gt 0) {
  $m = [regex]::Match($existing[-1].BaseName, '^(\d{4}-\d{2}-\d{2})-(\d{3})$')
  [int]$m.Groups[2].Value + 1
} else { 1 }

$filename = Join-Path $dirPath ('{0}-{1:D3}.md' -f $today, $next)

# No BOM. PowerShell 5.1 -Encoding UTF8 adds one.
[IO.File]::WriteAllText($filename, $Content, [Text.UTF8Encoding]::new($false))

if ((Get-Item $filename).Length -eq 0) {
  Remove-Item $filename -Force
  throw "wrote an empty file: $filename"
}

# Any byte above 0x7F means the handoff was corrupted in transit.
if (Select-String -Path $filename -Pattern '[^\x00-\x7F]' -AllMatches) {
  Remove-Item $filename -Force
  throw "non-ASCII written to $filename - file removed, fix the text"
}

$ignore = Join-Path (Get-Location) '.gitignore'
if (-not (Test-Path $ignore)) {
  Write-Warning 'no .gitignore - memory/ is not ignored and handoffs can be committed'
} elseif (-not (Select-String -Path $ignore -Pattern '^\s*memory/?\s*$' -Quiet)) {
  Write-Warning '.gitignore does not list memory/ - handoffs can be committed'
}

Write-Output $filename
exit 0

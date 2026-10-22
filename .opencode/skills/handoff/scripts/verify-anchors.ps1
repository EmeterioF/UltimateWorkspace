<#
  verify-anchors.ps1 - prove a handoff is safe to resume from.

  Resolves every [path:line] to real, non-blank content. A moved anchor is
  reported as MOVED with its new line and passes: an edit above it relocates
  the claim, it does not falsify it. DRIFT is reserved for quoted text that
  is gone from the file. Checks the four required fields, the optional
  project: target, the seven sections and the ASCII rule. Exit 1 on any failure.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Path)) { throw "handoff not found: $Path" }

$file = (Get-Item $Path).FullName
$fail = 0
$warn = 0
$count = 0

$anchors = Select-String -Path $file -Pattern '\[([^\]]+):(\d+)\](?:\s*"([^"]+)")?' -AllMatches
foreach ($m in $anchors.Matches) {
  $count++
  $p = $m.Groups[1].Value
  $n = [int]$m.Groups[2].Value
  $expect = $m.Groups[3].Value

  if (-not (Test-Path $p)) {
    Write-Output "MISSING  $p : $n"
    $fail++
    continue
  }

  $all = @(Get-Content $p)
  if ($n -lt 1 -or $n -gt $all.Count) {
    Write-Output "RANGE    $p : $n is past the end, the file has $($all.Count) line(s)"
    $fail++
    continue
  }

  $trim = $all[$n - 1].Trim()

  if ($expect) {
    $at = -1
    if ($trim) { $at = $trim.IndexOf($expect, [StringComparison]::OrdinalIgnoreCase) }

    if ($at -lt 0) {
      # The claim may still be true at another line. Search before failing:
      # an edit above the anchor moves it, it does not falsify it.
      $best = 0
      for ($i = 0; $i -lt $all.Count; $i++) {
        if ($all[$i].IndexOf($expect, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        $cand = $i + 1
        if ($best -eq 0 -or [math]::Abs($cand - $n) -lt [math]::Abs($best - $n)) { $best = $cand }
      }

      if ($best -gt 0) {
        Write-Output ('MOVED    {0} : {1} -> {2}  {3}' -f $p, $n, $best, $all[$best - 1].Trim())
        continue
      }

      if (-not $trim) {
        Write-Output "BLANK    $p : $n"
        $fail++
        continue
      }

      Write-Output "DRIFT    $p : $n expected '$expect' -> $trim"
      $fail++
      continue
    }
  } elseif (-not $trim) {
    Write-Output "BLANK    $p : $n"
    $fail++
    continue
  } elseif ($trim.StartsWith('#')) {
    Write-Output "WARN     $p : $n is a heading - quote it so drift can be caught"
    $warn++
  }

  Write-Output ('OK       {0} : {1} -> {2}' -f $p, $n, $trim)
}

$raw = Get-Content $file -Raw

foreach ($f in @('state:', 'next:', 'session:', 'changed:')) {
  if ($raw -notmatch ('(?m)^' + [regex]::Escape($f) + '\s*\S')) {
    Write-Output "FIELD    missing $f"
    $fail++
  }
}

# project: arrived after the first handoffs. Old files load with an unknown
# target and LOAD asks for a directory instead of failing the file.
$projMatch = [regex]::Match($raw, '(?m)^project:\s*(\S.*)$')
if (-not $projMatch.Success) {
  Write-Output 'PROJECT  no project: field - the next session must ask which directory'
  $warn++
} elseif (-not (Test-Path $projMatch.Groups[1].Value.Trim())) {
  Write-Output ("PROJECT  {0} is not on disk - the next session must ask which directory" -f $projMatch.Groups[1].Value.Trim())
  $warn++
}

# One group per required section. A group with two names is one slot with two
# accepted spellings, so handoffs written before the `Dead ends and traps`
# rename still verify. New handoffs must use the longer name.
$sections = @(
  ,@('Where we are')
  ,@('Open threads')
  ,@('Decisions')
  ,@('Bugs fixed')
  ,@('Dead ends', 'Dead ends and traps')
  ,@('Verify')
  ,@('Suggested skills')
)

foreach ($group in $sections) {
  $hit = $false
  foreach ($name in $group) {
    if ($raw -match ('(?m)^## ' + [regex]::Escape($name) + '\s*$')) { $hit = $true }
  }
  if (-not $hit) {
    Write-Output ('SECTION  missing ## ' + ($group -join ' or ## '))
    $fail++
  }
}

if (Select-String -Path $file -Pattern '[^\x00-\x7F]' -AllMatches) {
  Write-Output 'ASCII    file contains non-ASCII bytes'
  $fail++
}

Write-Output ''
Write-Output "anchors: $count checked, $fail failure(s), $warn warning(s)"
if ($fail -gt 0) { exit 1 }
exit 0

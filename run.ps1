param(
    [Parameter(Mandatory=$false)] [string]$Json,
    [Parameter(Mandatory=$false)] [string]$File,
    [Parameter(Mandatory=$false)] [switch]$ScreenshotLast
)
. (Join-Path $PSScriptRoot 'core.ps1')
if ($File) { $Json = Get-Content -Raw -LiteralPath $File }
if (-not $Json) { throw "Provide -Json or -File" }
$seq = $Json | ConvertFrom-Json
$results = @()
foreach ($step in $seq) {
    $a = $step.action
    $Arguments = @()
    if ($step.args) { $Arguments = @($step.args) }
    $r = Execute-LocalControl -Action $a -Arguments $Arguments
    $results += $r
    if ($step.delay) { Start-Sleep -Milliseconds $step.delay }
}
if ($ScreenshotLast) {
    $shot = Execute-LocalControl -Action 'screenshot' -Arguments @()
    $results += $shot
}
$results



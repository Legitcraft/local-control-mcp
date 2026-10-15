. (Join-Path $PSScriptRoot 'core.ps1')
$runFile = Join-Path $PSScriptRoot 'run.json'
$resultFile = Join-Path $PSScriptRoot 'result.txt'
Write-Host "Daemon ready. Write batch JSON to $runFile to execute."
while ($true) {
    if (Test-Path $runFile) {
        try {
            $json = Get-Content -Raw -LiteralPath $runFile
            $seq = $json | ConvertFrom-Json
            $out = @()
            foreach ($step in $seq) {
                $args = @(); if ($step.args) { $args = @($step.args) }
                $out += (Execute-LocalControl -Action $step.action -Arguments $args)
                if ($step.delay) { Start-Sleep -Milliseconds $step.delay }
            }
            $out | Set-Content -LiteralPath $resultFile
        } catch {
            $_ | Out-String | Set-Content -LiteralPath $resultFile
        } finally {
            Remove-Item -LiteralPath $runFile -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Milliseconds 30
}

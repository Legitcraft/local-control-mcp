param(
    [Parameter(Mandatory)] [string]$Action,
    [Parameter(ValueFromRemainingArguments=$true)] [string[]]$Arguments
)
. (Join-Path $PSScriptRoot 'core.ps1')
Execute-LocalControl -Action $Action -Arguments $Arguments


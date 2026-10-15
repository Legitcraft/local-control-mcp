param([switch]$Send)
$to = 'hello@linkminute.com'
$subject = 'Thank you for the meeting'
$body = "Hi,`n`nThank you for your time and for the meeting today. I appreciate it.`n`nBest,`nlegitcraft"
$url = "https://mail.google.com/mail/?view=cm&fs=1&to=$([System.Uri]::EscapeDataString($to))&su=$([System.Uri]::EscapeDataString($subject))&body=$([System.Uri]::EscapeDataString($body))"
Start-Process msedge -ArgumentList "--new-window", $url
Start-Sleep -Seconds 8
if ($Send) {
    powershell -ExecutionPolicy Bypass -NoProfile -File (Join-Path $PSScriptRoot 'control.ps1') key 'ctrl+enter'
    Start-Sleep -Seconds 2
}
powershell -ExecutionPolicy Bypass -NoProfile -File (Join-Path $PSScriptRoot 'control.ps1') screenshot


Add-Type @"
using System;
using System.Runtime.InteropServices;
public class LCWatch {
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
"@
$stopFile = "$env:TEMP\local-control.stop"
Write-Host "Emergency stop armed. Press Ctrl+Alt+Shift+Esc to abort. (Ctrl+C to disarm)"
while ($true) {
    $ctrl = [LCWatch]::GetAsyncKeyState(0x11) -band 0x8000
    $alt  = [LCWatch]::GetAsyncKeyState(0x12) -band 0x8000
    $shift= [LCWatch]::GetAsyncKeyState(0x10) -band 0x8000
    $esc  = [LCWatch]::GetAsyncKeyState(0x1B) -band 0x8000
    if ($ctrl -and $alt -and $shift -and $esc) {
        New-Item -ItemType File -Force -Path $stopFile | Out-Null
        Write-Host "STOP triggered. Flag: $stopFile"
        break
    }
    Start-Sleep -Milliseconds 40
}


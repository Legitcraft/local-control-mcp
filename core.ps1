$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing, System.Windows.Forms

$src = @"
using System;
using System.Runtime.InteropServices;
public static class LCNative {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT pt);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern IntPtr FindWindow(string cls, string name);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    public struct POINT { public int x; public int y; }
    public const uint LEFTDOWN=0x0002, LEFTUP=0x0004, RIGHTDOWN=0x0008, RIGHTUP=0x0010,
        MIDDLEDOWN=0x0020, MIDDLEUP=0x0040, WHEEL=0x0800;
    public const uint KEYEVENTF_KEYUP=0x0002;
}
"@
Add-Type -TypeDefinition $src

$script:vkMap = @{
    "enter"=0x0D; "tab"=0x09; "esc"=0x1B; "space"=0x20; "backspace"=0x08; "delete"=0x2E;
    "up"=0x26; "down"=0x28; "left"=0x25; "right"=0x27; "home"=0x24; "end"=0x23;
    "pageup"=0x21; "pagedown"=0x22; "f1"=0x70; "f2"=0x71; "f3"=0x72; "f4"=0x73;
    "f5"=0x74; "f6"=0x75; "f7"=0x76; "f8"=0x77; "f9"=0x78; "f10"=0x79; "f11"=0x7A; "f12"=0x7B;
    "a"=0x41;"b"=0x42;"c"=0x43;"d"=0x44;"e"=0x45;"f"=0x46;"g"=0x47;"h"=0x48;"i"=0x49;"j"=0x4A;
    "k"=0x4B;"l"=0x4C;"m"=0x4D;"n"=0x4E;"o"=0x4F;"p"=0x50;"q"=0x51;"r"=0x52;"s"=0x53;"t"=0x54;
    "u"=0x55;"v"=0x56;"w"=0x57;"x"=0x58;"y"=0x59;"z"=0x5A; "0"=0x30;"1"=0x31;"2"=0x32;"3"=0x33;
    "4"=0x34;"5"=0x35;"6"=0x36;"7"=0x37;"8"=0x38;"9"=0x39
}

function TapKey($vk, [bool]$up=$false) {
    $flag = 0; if ($up) { $flag = [LCNative]::KEYEVENTF_KEYUP }
    [LCNative]::keybd_event($vk, 0, $flag, [IntPtr]::Zero)
}

function SendCombo($combo) {
    $parts = $combo -split '\+' | ForEach-Object { $_.Trim().ToLower() }
    $mods = @(); $key = $null
    foreach ($p in $parts) {
        if ($p -eq "ctrl" -or $p -eq "control") { $mods += 0x11 }
        elseif ($p -eq "shift") { $mods += 0x10 }
        elseif ($p -eq "alt") { $mods += 0x12 }
        elseif ($p -eq "win" -or $p -eq "windows") { $mods += 0x5B }
        else { $key = $p }
    }
    foreach ($m in $mods) { TapKey $m }
    if ($key) {
        if (-not $script:vkMap.ContainsKey($key)) { throw "Unknown key: $key" }
        $v = $script:vkMap[$key]; TapKey $v; Start-Sleep -Milliseconds 5; TapKey $v $true
    }
    for ($i=$mods.Count-1; $i -ge 0; $i--) { TapKey $mods[$i] $true }
}

function Execute-LocalControl {
    param([string]$Action,[string[]]$Arguments)
    $Action = $Action.ToLower()
    $stopFile = "$env:TEMP\local-control.stop"
    function Abort-IfStop { if (Test-Path $stopFile) { throw "STOP requested ($stopFile)" } }
    switch ($Action) {
        "move" { Abort-IfStop; [LCNative]::SetCursorPos([int]$Arguments[0],[int]$Arguments[1]) | Out-Null; Write-Output "moved to $($Arguments[0]),$($Arguments[1])" }
        "pos" { $p = New-Object LCNative+POINT; [LCNative]::GetCursorPos([ref]$p) | Out-Null; Write-Output "$($p.x) $($p.y)" }
        "click" {
            Abort-IfStop
            $btn = "left"
            if ($Arguments.Count -ge 3) { $btn = $Arguments[2].ToLower() }
            elseif ($Arguments.Count -eq 1 -and $Arguments[0] -notmatch '^\d+$') { $btn = $Arguments[0].ToLower() }
            if ($Arguments.Count -ge 2 -and $Arguments[0] -match '^\d+$') { [LCNative]::SetCursorPos([int]$Arguments[0],[int]$Arguments[1]) | Out-Null; Start-Sleep -Milliseconds 5 }
            switch ($btn) {
                "left"   { [LCNative]::mouse_event([LCNative]::LEFTDOWN,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 5; [LCNative]::mouse_event([LCNative]::LEFTUP,0,0,0,[IntPtr]::Zero) }
                "right"  { [LCNative]::mouse_event([LCNative]::RIGHTDOWN,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 5; [LCNative]::mouse_event([LCNative]::RIGHTUP,0,0,0,[IntPtr]::Zero) }
                "middle" { [LCNative]::mouse_event([LCNative]::MIDDLEDOWN,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 5; [LCNative]::mouse_event([LCNative]::MIDDLEUP,0,0,0,[IntPtr]::Zero) }
                "double" { 1..2 | ForEach-Object { [LCNative]::mouse_event([LCNative]::LEFTDOWN,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 5; [LCNative]::mouse_event([LCNative]::LEFTUP,0,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 10 } }
                default { throw "Unknown button: $btn" }
            }
            Write-Output "clicked $btn"
        }
        "scroll" { Abort-IfStop; $delta = [int]$Arguments[0] * 120; [LCNative]::mouse_event([LCNative]::WHEEL,0,0,$delta,[IntPtr]::Zero); Write-Output "scrolled $($Arguments[0])" }
        "type" { Abort-IfStop; $text = $Arguments -join " "; [System.Windows.Forms.SendKeys]::SendWait($text); Write-Output "typed" }
        "key" { Abort-IfStop; $combo = $Arguments -join " "; SendCombo $combo; Write-Output "key $combo" }
        "screenshot" {
            Abort-IfStop
            $out = if ($Arguments.Count -gt 0 -and $Arguments[0]) { $Arguments[0] } else { "$env:TEMP\screenshot-$(Get-Date -Format yyyyMMdd-HHmmss).png" }
            $b = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
            $g = [System.Drawing.Graphics]::FromImage($b)
            $g.CopyFromScreen(0,0,0,0,$b.Size)
            $b.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
            $g.Dispose(); $b.Dispose()
            Write-Output $out
        }
        "windows" { Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Id, ProcessName, MainWindowTitle | Format-Table -AutoSize }
        "activate" { Abort-IfStop; $title = $Arguments -join " "; $p = Get-Process | Where-Object { $_.MainWindowTitle -like "*$title*" } | Select-Object -First 1; if (-not $p) { throw "No window matching: $title" }; [LCNative]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; Write-Output "activated $($p.MainWindowTitle)" }
        "clipboard" { $text = $Arguments -join " "; Set-Clipboard -Value $text; Write-Output "clipboard set" }
        "paste" { [System.Windows.Forms.SendKeys]::SendWait("^v"); Write-Output "pasted" }
        "stop-file" { New-Item -ItemType File -Force -Path $stopFile | Out-Null; Write-Output "stop flag created" }
        "clear-stop" { if (Test-Path $stopFile) { Remove-Item $stopFile -Force }; Write-Output "stop flag cleared" }
        "cleanup-screenshots" { Get-ChildItem "$env:TEMP\screenshot-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force; Write-Output "cleaned" }
        default { throw "Unknown action: $Action" }
    }
}









for ($i=0; $i -lt 8; $i++) {
    & 'C:\Users\SAQIB\Desktop\local-control-skill\control.ps1' key 'tab'
    Start-Sleep -Milliseconds 120
}
Start-Sleep -Milliseconds 300
& 'C:\Users\SAQIB\Desktop\local-control-skill\control.ps1' key 'enter'
Start-Sleep -Seconds 4
& 'C:\Users\SAQIB\Desktop\local-control-skill\control.ps1' screenshot


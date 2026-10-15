$ctrl = 'C:\Users\SAQIB\Desktop\local-control-skill\control.ps1'
$urls = @(
  'https://artificialanalysis.ai/leaderboards/models',
  'https://arena.ai/leaderboard',
  'https://www.benchleader.com'
)
# Ensure Edge frontmost
& $ctrl activate 'Edge' ; Start-Sleep -Milliseconds 500
foreach ($u in $urls) {
  & $ctrl key 'ctrl+t'; Start-Sleep -Milliseconds 700
  & $ctrl type $u; Start-Sleep -Milliseconds 300
  & $ctrl key 'enter'; Start-Sleep -Seconds 5
}
& $ctrl screenshot


$ErrorActionPreference = 'Stop'
$phase = 'start'
try {
  $phase = 'install'
  $setup = (Get-ChildItem dist/CampusFoodWaste-Setup-*-x64.exe).FullName
  $destination = Join-Path $env:RUNNER_TEMP 'CampusFoodWasteInstalled'
  $phase = 'legacy-install'
  $legacy = Join-Path $env:RUNNER_TEMP 'CampusFoodWaste-Setup-1.0.0-x64.exe'
  $base = 'https://github.com/chun20220128-maker/-/releases/download/desktop-v1.0.0/'
  Invoke-WebRequest ($base + 'CampusFoodWaste-Setup-1.0.0-x64.exe') -OutFile $legacy
  $checkFile = Join-Path $env:RUNNER_TEMP 'legacy-SHA256SUMS.txt'
  Invoke-WebRequest ($base + 'SHA256SUMS.txt') -OutFile $checkFile
  $checks = Get-Content $checkFile -Raw
  $expected = (($checks -split "`n" | Where-Object { $_ -match 'CampusFoodWaste-Setup-1.0.0-x64.exe' }) -split '\s+')[0]
  if ((Get-FileHash $legacy -Algorithm SHA256).Hash.ToLower() -ne $expected.ToLower()) { throw 'Legacy installer checksum mismatch' }
  $oldInstall = Start-Process -FilePath $legacy -ArgumentList @('/S', "/D=$destination") -Wait -PassThru
  if ($oldInstall.ExitCode -ne 0) { throw 'Legacy install failed' }
  $realData = Join-Path $env:APPDATA 'CampusFoodWaste'
  node scripts/seed-upgrade.cjs $realData
  if ($LASTEXITCODE -ne 0) { throw 'Could not create legacy data' }
  $env:CAMPUS_UPGRADE_DATA = $realData
  $env:CAMPUS_ELECTRON_EXECUTABLE = Join-Path $destination '校園廚餘管理.exe'
  $env:CAMPUS_UPGRADE_PHASE = 'before'
  node test/upgrade.e2e.cjs *> upgrade-before.txt
  $beforeCode = $LASTEXITCODE
  Get-Content upgrade-before.txt
  if ($beforeCode -ne 0) { throw 'Installed legacy app data check failed' }
  Remove-Item Env:CAMPUS_ELECTRON_EXECUTABLE
  $phase = 'upgrade-install'
  $p = Start-Process -FilePath $setup -ArgumentList @('/S', "/D=$destination") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Install failed: $($p.ExitCode)" }
  $exe = Join-Path $destination '校園廚餘管理.exe'
  if (!(Test-Path $exe)) { throw 'Installed executable missing' }
  $phase = 'desktop-shortcut'
  $desktopLink = Join-Path ([Environment]::GetFolderPath('Desktop')) '校園廚餘管理.lnk'
  if (!(Test-Path $desktopLink)) { throw 'Desktop shortcut missing' }
  node scripts/verify-shortcut.cjs $desktopLink $exe
  if ($LASTEXITCODE -ne 0) { throw "Desktop shortcut does not resolve to the installed executable" }
  $phase = 'upgrade-data-check'
  $env:CAMPUS_ELECTRON_EXECUTABLE = $exe
  $env:CAMPUS_UPGRADE_PHASE = 'after'
  node test/upgrade.e2e.cjs *> upgrade-after.txt
  $afterCode = $LASTEXITCODE
  Get-Content upgrade-after.txt
  if ($afterCode -ne 0) { throw 'Upgrade data preservation check failed' }
  Remove-Item Env:CAMPUS_UPGRADE_PHASE
  Remove-Item Env:CAMPUS_UPGRADE_DATA
  $phase = 'installed-app'
  $env:CAMPUS_ELECTRON_EXECUTABLE = $exe
  npm run test:desktop *> installed-app-test.txt
  $testCode = $LASTEXITCODE
  Get-Content installed-app-test.txt
  if ($testCode -ne 0) { throw 'Installed application test failed' }
  Remove-Item Env:CAMPUS_ELECTRON_EXECUTABLE
  $phase = 'uninstall'
  $dataDir = Join-Path $env:APPDATA 'CampusFoodWaste'
  New-Item -ItemType Directory -Force $dataDir | Out-Null
  $probe = Join-Path $dataDir 'uninstall-preservation-test.txt'
  Set-Content $probe 'Must survive uninstall'
  $uninstall = Join-Path $destination '解除安裝.exe'
  $dbFile = Join-Path $dataDir 'campus-food-waste.sqlite'
  $dbHash = (Get-FileHash $dbFile -Algorithm SHA256).Hash
  $u = Start-Process -FilePath $uninstall -ArgumentList '/S' -Wait -PassThru
  for ($i=0; $i -lt 20 -and (Test-Path $exe); $i++) { Start-Sleep -Seconds 1 }
  if (Test-Path $exe) { throw 'Uninstall did not remove application' }
  if (!(Test-Path $probe)) { throw 'Uninstall removed user data' }
  if ((Get-FileHash $dbFile -Algorithm SHA256).Hash -ne $dbHash) { throw 'Uninstall changed database' }
  'Windows installation, shortcut, installed app, uninstall and data retention verified.' | Add-Content $env:GITHUB_STEP_SUMMARY
} catch {
  $message = "Windows verification phase $phase failed: $($_.Exception.Message)"
  Write-Output "::error::$message"
  "## $message" | Add-Content $env:GITHUB_STEP_SUMMARY
  '```text' | Add-Content $env:GITHUB_STEP_SUMMARY
  ($_ | Out-String) | Add-Content $env:GITHUB_STEP_SUMMARY
  foreach ($log in @('upgrade-before.txt','upgrade-after.txt')) { if (Test-Path $log) { Get-Content $log -Tail 100 | Add-Content $env:GITHUB_STEP_SUMMARY } }
  if (Test-Path installed-app-test.txt) { Get-Content installed-app-test.txt -Tail 100 | Add-Content $env:GITHUB_STEP_SUMMARY }
  '```' | Add-Content $env:GITHUB_STEP_SUMMARY
  throw
}

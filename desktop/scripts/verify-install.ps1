$ErrorActionPreference = 'Stop'
$phase = 'start'
try {
  $phase = 'install'
  $setup = (Get-ChildItem dist/CampusFoodWaste-Setup-*-x64.exe).FullName
  $destination = Join-Path $env:RUNNER_TEMP 'CampusFoodWasteInstalled'
  $p = Start-Process -FilePath $setup -ArgumentList @('/S', "/D=$destination") -Wait -PassThru
  if ($p.ExitCode -ne 0) { throw "Install failed: $($p.ExitCode)" }
  $exe = Join-Path $destination '校園廚餘管理.exe'
  if (!(Test-Path $exe)) { throw 'Installed executable missing' }
  $phase = 'desktop-shortcut'
  $desktopLink = Join-Path ([Environment]::GetFolderPath('Desktop')) '校園廚餘管理.lnk'
  if (!(Test-Path $desktopLink)) { throw 'Desktop shortcut missing' }
  $shell = New-Object -ComObject WScript.Shell
  if ($shell.CreateShortcut($desktopLink).TargetPath -ne $exe) { throw 'Desktop shortcut target incorrect' }
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
  $u = Start-Process -FilePath $uninstall -ArgumentList '/S' -Wait -PassThru
  for ($i=0; $i -lt 20 -and (Test-Path $exe); $i++) { Start-Sleep -Seconds 1 }
  if (Test-Path $exe) { throw 'Uninstall did not remove application' }
  if (!(Test-Path $probe)) { throw 'Uninstall removed user data' }
  'Windows installation, shortcut, installed app, uninstall and data retention verified.' | Add-Content $env:GITHUB_STEP_SUMMARY
} catch {
  $message = "Windows verification phase $phase failed: $($_.Exception.Message)"
  Write-Output "::error::$message"
  "## $message" | Add-Content $env:GITHUB_STEP_SUMMARY
  '```text' | Add-Content $env:GITHUB_STEP_SUMMARY
  ($_ | Out-String) | Add-Content $env:GITHUB_STEP_SUMMARY
  if (Test-Path installed-app-test.txt) { Get-Content installed-app-test.txt -Tail 100 | Add-Content $env:GITHUB_STEP_SUMMARY }
  '```' | Add-Content $env:GITHUB_STEP_SUMMARY
  throw
}

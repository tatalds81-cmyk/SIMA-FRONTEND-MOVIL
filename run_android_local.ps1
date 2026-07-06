$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

if (-not (Test-Path $adb)) {
    throw 'No se encontro ADB en el SDK de Android.'
}

& $adb start-server | Out-Null
$devices = & $adb devices
$connected = $devices | Select-String "\tdevice$"

if (-not $connected) {
    throw 'No hay un celular autorizado. Conectalo por USB, activa Depuracion USB y acepta la autorizacion.'
}

& $adb reverse tcp:3000 tcp:3000
if ($LASTEXITCODE -ne 0) {
    throw 'No fue posible crear el tunel USB hacia el backend local.'
}

Write-Host 'Tunel USB listo: celular:3000 -> PC:3000' -ForegroundColor Green
flutter run

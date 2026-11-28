# Suite automatizada en el teléfono conectado por USB (auditoría, sección 3).
# Uso (desde src/mobile/nexo_app):
#   powershell -ExecutionPolicy Bypass -File tools/pruebas-dispositivo.ps1
#   powershell -ExecutionPolicy Bypass -File tools/pruebas-dispositivo.ps1 -Modo live
param(
    [ValidateSet('fake', 'live')] [string] $Modo = 'fake',
    [string] $Dispositivo = ''
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $Dispositivo) {
    # Primer dispositivo Android físico autorizado (no emuladores).
    $lineas = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' -and $_ -notmatch '^emulator-' }
    if (-not $lineas) { throw 'No hay un teléfono Android conectado y autorizado (adb devices). Activa la depuración USB.' }
    $Dispositivo = ($lineas | Select-Object -First 1).Split("`t")[0]
}
Write-Host "Dispositivo: $Dispositivo  ·  API_MODE=$Modo"

flutter test integration_test -d $Dispositivo --dart-define=API_MODE=$Modo --reporter expanded
exit $LASTEXITCODE

param(
    [ValidateSet('start', 'status', 'reload', 'restart', 'stop', 'help')]
    [string]$Action = 'start',
    [string]$TemplateAvd,
    [string]$ServerUrl,
    [string]$FlutterSdk,
    [string]$AndroidSdk,
    [string]$JavaHome,
    [switch]$Rebuild,
    [switch]$NoWatch,
    [switch]$NoMirror
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 20+ is required.' }
$launchArgs = @((Join-Path $PSScriptRoot 'dev-multi.mjs'), $Action)
foreach ($pair in @(
    @('--template-avd', $TemplateAvd), @('--server-url', $ServerUrl),
    @('--flutter-sdk', $FlutterSdk), @('--android-sdk', $AndroidSdk), @('--java-home', $JavaHome)
)) {
    if ($pair[1]) { $launchArgs += $pair }
}
if ($Rebuild) { $launchArgs += '--rebuild' }
if ($NoWatch) { $launchArgs += '--no-watch' }
if ($NoMirror) { $launchArgs += '--no-mirror' }
& node @launchArgs
exit $LASTEXITCODE

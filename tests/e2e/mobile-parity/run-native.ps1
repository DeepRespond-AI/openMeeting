param(
    [string]$DeviceId = $env:OPENMEETING_E2E_DEVICE,
    [string]$FlutterSdk = $env:FLUTTER_ROOT
)
$ErrorActionPreference='Stop'
if ([string]::IsNullOrWhiteSpace($DeviceId)) { throw 'Set OPENMEETING_E2E_DEVICE or pass -DeviceId with a dedicated device from adb devices.' }
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$out=Join-Path $repoRoot '.artifacts\mobile-desktop-parity'
$budget=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $out 'e2e-budget.json') | ConvertFrom-Json
if (([DateTime]::UtcNow-[DateTime]::Parse($budget.firstAttempt).ToUniversalTime()).TotalMinutes -gt 30) { throw 'Native E2E budget exhausted; use API fallback.' }
if ($FlutterSdk) { $env:PATH=(Join-Path $FlutterSdk 'bin')+[IO.Path]::PathSeparator+$env:PATH }
if (-not $env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME=Join-Path $out 'gradle-cache' }
$env:OPENMEETING_ANDROID_DEBUG_SUFFIX='.parity'
$env:OPENMEETING_NATIVE_ACCEPTANCE='1'
$env:OPENMEETING_NATIVE_ACCEPTANCE_NO_GOLDENS='1'
$env:HTTP_PROXY=$null
$env:HTTPS_PROXY=$null
$env:ALL_PROXY=$null
$env:NO_PROXY='localhost,127.0.0.1,::1'
$attempt=@(Get-ChildItem -LiteralPath (Join-Path $out 'logs') -Filter 'native-attempt-*.txt').Count+1
$log=Join-Path $out ('logs\native-attempt-{0:D2}.txt' -f $attempt)
$code=1
try {
    Set-Location (Join-Path $repoRoot 'mobile')
    $ErrorActionPreference='Continue'
    flutter test integration_test/desktop_parity_test.dart -d $DeviceId --no-uninstall --no-dds --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39330 "--dart-define=E2E_ATTEMPT=$attempt" --reporter expanded --verbose *> $log
    $code=$LASTEXITCODE
} finally {
    $result=@{attempt=$attempt;passed=($code -eq 0);exitCode=$code;finishedAt=[DateTime]::UtcNow.ToString('o');applicationId='cn.deeprespond.meeting.parity'}|ConvertTo-Json
    [IO.File]::WriteAllText((Join-Path $out 'native-run.json'),$result,[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $out ('native-run-attempt-{0:D2}.json' -f $attempt)),$result,[Text.UTF8Encoding]::new($false))
}
exit $code

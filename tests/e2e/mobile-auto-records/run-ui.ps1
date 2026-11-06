$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$out=Join-Path $repoRoot '.artifacts/mobile-auto-records'
$budgetFile=Join-Path $out 'e2e-budget.json'
if (-not (Test-Path -LiteralPath $budgetFile)) {
    [IO.File]::WriteAllText($budgetFile,(@{firstAttempt=[DateTime]::UtcNow.ToString('o');limitMinutes=30;scope='automatic recording and shared record UI regression'}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
}
$budget=Get-Content -Raw -Encoding UTF8 -LiteralPath $budgetFile | ConvertFrom-Json
if (([DateTime]::UtcNow-[DateTime]::Parse($budget.firstAttempt).ToUniversalTime()).TotalMinutes -ge 30) { throw 'E2E budget exhausted. Keep history and use API validation.' }
$attempt=@(Get-ChildItem -LiteralPath (Join-Path $out 'logs') -Filter 'ui-attempt-*.txt').Count+1
if ($env:FLUTTER_ROOT) { $env:PATH=(Join-Path $env:FLUTTER_ROOT 'bin')+[IO.Path]::PathSeparator+$env:PATH }
$env:MOBILE_AUTO_RECORDS_UI='1'
$env:NO_PROXY='localhost,127.0.0.1,::1'
Set-Location (Join-Path $repoRoot 'mobile')
$ErrorActionPreference='Continue'
flutter test test/acceptance/automatic_recording_ui_test.dart --reporter expanded *> (Join-Path $out ('logs/ui-attempt-{0:D2}.txt' -f $attempt))
$code=$LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $out 'ui-run.json'),(@{attempt=$attempt;passed=($code -eq 0);exitCode=$code;finishedAt=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
exit $code

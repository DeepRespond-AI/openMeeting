[CmdletBinding()]
param(
    [switch]$Build
)

# Export the current CPU server images; -Build rebuilds them before exporting.
# Real .env files and Docker volume data are never copied into the package.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$previousPlatform = $env:DOCKER_DEFAULT_PLATFORM
$utf8 = New-Object System.Text.UTF8Encoding($false)

Push-Location $repoRoot
try {
    Get-Command docker, tar -ErrorAction Stop | Out-Null

    if ($Build) {
        $env:DOCKER_DEFAULT_PLATFORM = 'linux/amd64'
        docker compose -f server/docker-compose.yml --profile minio build
        if ($LASTEXITCODE -ne 0) { throw 'Image build failed.' }
        docker pull --platform linux/amd64 postgres:16
        if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL image pull failed.' }
    }

    $packageDir = Join-Path $repoRoot ('.artifacts/offline-deploy-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-linux-amd64')
    New-Item -ItemType Directory -Path $packageDir | Out-Null

    # Keep runtime placeholders and exclude local Compose overrides and secrets.
    $raw = docker compose -f server/docker-compose.yml config --no-interpolate --no-env-resolution --format json
    if ($LASTEXITCODE -ne 0) { throw 'Compose configuration export failed.' }
    $compose = ($raw -join [Environment]::NewLine) | ConvertFrom-Json
    $migrationImages = @{ 'user-migrate' = 'user_ms'; 'meeting-migrate' = 'meeting_ms'; 'stt-migrate' = 'stt_ms' }
    foreach ($entry in $compose.services.PSObject.Properties) {
        $service = $entry.Value
        if ($service.build) {
            $imageService = $entry.Name
            if ($migrationImages.ContainsKey($entry.Name)) { $imageService = $migrationImages[$entry.Name] }
            $service | Add-Member -NotePropertyName image -NotePropertyValue ("openmeeting-split-${imageService}:latest") -Force
        }
        $service.PSObject.Properties.Remove('build')
        $service | Add-Member -NotePropertyName platform -NotePropertyValue 'linux/amd64' -Force
        $service | Add-Member -NotePropertyName pull_policy -NotePropertyValue 'never' -Force
        if (@($service.volumes | Where-Object type -eq 'bind').Count) {
            throw "Host bind mounts cannot be exported: $($entry.Name)"
        }
    }

    $offlineCompose = Join-Path $packageDir 'docker-compose.offline.json'
    [IO.File]::WriteAllText($offlineCompose, ($compose | ConvertTo-Json -Depth 100), $utf8)
    Copy-Item server/.env.example (Join-Path $packageDir '.env.example')

    $images = @($compose.services.PSObject.Properties | ForEach-Object { $_.Value.image } | Sort-Object -Unique)
    foreach ($image in $images) {
        $platform = docker image inspect --format '{{.Os}}/{{.Architecture}}' $image
        if ($LASTEXITCODE -ne 0 -or $platform -ne 'linux/amd64') {
            throw "Missing image or wrong platform: $image. Build linux/amd64 images first."
        }
    }
    [IO.File]::WriteAllLines((Join-Path $packageDir 'image-list.txt'), [string[]]$images, $utf8)
    docker compose --env-file (Join-Path $packageDir '.env.example') -f $offlineCompose config --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Offline Compose validation failed.' }

    docker image save --output (Join-Path $packageDir 'images.tar') @images
    if ($LASTEXITCODE -ne 0) { throw 'Image export failed.' }

    $files = @('images.tar', 'image-list.txt', 'docker-compose.offline.json', '.env.example')
    $checksums = foreach ($file in $files) {
        (Get-FileHash (Join-Path $packageDir $file) -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + $file
    }
    [IO.File]::WriteAllLines((Join-Path $packageDir 'SHA256SUMS'), [string[]]$checksums, $utf8)
    $archive = Join-Path $packageDir 'shenying-meeting-linux-amd64.tar.gz'
    tar -czf $archive -C $packageDir @files SHA256SUMS
    if ($LASTEXITCODE -ne 0) { throw 'Package compression failed.' }
    $archiveHash = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText(($archive + '.sha256'), ($archiveHash + '  ' + [IO.Path]::GetFileName($archive) + "`n"), $utf8)

    Write-Output "Package: $archive"
    Write-Output "SHA-256: $archive.sha256"
    Write-Output "Images: $($images.Count); linux/amd64 CPU. No database, recordings or model volumes included."
}
finally {
    $env:DOCKER_DEFAULT_PLATFORM = $previousPlatform
    Pop-Location
}

# Load .env values into the current PowerShell session without logging values.

function Load-EnvFile {
    param(
        [string]$EnvFilePath = ".env",
        [switch]$Verbose = $false
    )

    # Check if .env file exists
    if (-not (Test-Path -LiteralPath $EnvFilePath)) {
        if ($Verbose) {
            Write-Host "No .env file found at: $EnvFilePath" -ForegroundColor Yellow
        }
        return $false
    }

    if ($Verbose) {
        Write-Host "Loading environment variables from: $EnvFilePath" -ForegroundColor Cyan
    }

    $loadedCount = 0
    $lineNumber = 0

    try {
        Get-Content -LiteralPath $EnvFilePath -Encoding UTF8 -ErrorAction Stop | ForEach-Object {
            $lineNumber++
            $line = $_.Trim()

            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                return
            }

            # Parse KEY=VALUE format
            if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$') {
                $key = $matches[1]
                $value = $matches[2].Trim()

                # Remove surrounding quotes if present
                if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                    $value = $matches[1]
                }

                # Set environment variable
                Set-Item -Path "env:$key" -Value $value -Force -ErrorAction Stop

                if ($Verbose) {
                    # Even ordinary variable names can contain credentials or private URLs.
                    $state = if ($value.Length -gt 0) { 'SET' } else { 'EMPTY' }
                    Write-Host "   Loaded: $key ($state)" -ForegroundColor Green
                }

                $loadedCount++
            }
            else {
                # Malformed lines can also contain secrets, so only report their location.
                Write-Warning "Skipping invalid line $lineNumber in .env."
            }
        }

        if ($Verbose) {
            Write-Host "Loaded $loadedCount environment variable(s) from .env" -ForegroundColor Green
            Write-Host ""
        }

        return $true
    }
    catch {
        # Exception messages can contain the failing input value.
        Write-Error "Failed to load .env file. Check its syntax and permissions."
        return $false
    }
}

# build.ps1 dot-sources this file; exporting is only valid inside a module.
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Load-EnvFile
}

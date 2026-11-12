<#
.SYNOPSIS
Verifies and runs the compiled installer beside this script.
.DESCRIPTION
Requires installer.exe and its ASCII SHA-256 sidecar in the script directory.
All arguments and the installer's exit code are forwarded. The checksum must
come from a trusted source; it does not authenticate the publisher.
.EXAMPLE
.\install\install.ps1
#>
$ErrorActionPreference = 'Stop'

function Assert-FileHash {
    param([Parameter(Mandatory)][string]$Path)

    $expectedHash = (Get-Content "$Path.sha256" -Raw).Trim()
    if ($expectedHash -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Invalid SHA-256 checksum file: $Path.sha256"
    }
    if ((Get-FileHash $Path -Algorithm SHA256).Hash -ne $expectedHash) {
        throw "SHA-256 mismatch. Execution refused: $Path"
    }
}

function Invoke-Installer {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string[]]$InstallerArguments = @()
    )

    # Native stderr must not become a terminating error under PowerShell 5.1.
    $ErrorActionPreference = 'Continue'
    & $Path @InstallerArguments
    exit $LASTEXITCODE
}

$executable = Join-Path $PSScriptRoot 'installer.exe'
Assert-FileHash -Path $executable
Invoke-Installer -Path $executable -InstallerArguments $args

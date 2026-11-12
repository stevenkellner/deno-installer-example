<#
.SYNOPSIS
Verifies, extracts, and runs the portable source installer.
.DESCRIPTION
Requires install-src.zip and its ASCII SHA-256 sidecar beside this script.
Extraction overwrites files in the script directory and retains them afterward.
The archive must contain deno.exe and src/install.ts. Arguments and the native
exit code are forwarded. A trusted checksum is required, not just a matching one.
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
        throw "SHA-256 mismatch. Extraction refused: $Path"
    }
}

function Expand-Installer {
    param(
        [Parameter(Mandatory)][string]$Archive,
        [Parameter(Mandatory)][string]$Destination
    )

    # Keep the runtime and source beside the launcher for subsequent use.
    Expand-Archive $Archive $Destination -Force
    if (-not (Test-Path (Join-Path $Destination 'deno.exe') -PathType Leaf) -or
        -not (Test-Path (Join-Path $Destination 'src/install.ts') -PathType Leaf)) {
        throw 'Archive is missing the runtime or installer entry point.'
    }
}

function Invoke-Installer {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [string[]]$InstallerArguments = @()
    )

    Push-Location $Directory
    try {
        # Native stderr must not become a terminating error under PowerShell 5.1.
        $ErrorActionPreference = 'Continue'
        & (Join-Path $Directory 'deno.exe') run --allow-all src/install.ts @InstallerArguments
        exit $LASTEXITCODE
    } finally {
        $ErrorActionPreference = 'Stop'
        Pop-Location
    }
}

$archive = Join-Path $PSScriptRoot 'install-src.zip'
Assert-FileHash -Path $archive
Expand-Installer -Archive $archive -Destination $PSScriptRoot
Invoke-Installer -Directory $PSScriptRoot -InstallerArguments $args

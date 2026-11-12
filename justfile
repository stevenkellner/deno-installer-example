
set shell := ["powershell.exe", "-NoLogo", "-Command"]

CI_SHELL := env_var_or_default("CI_SHELL", "powershell.exe")
JUST_RUNNER := if CI_SHELL == "pwsh" { "just --shell pwsh --shell-arg=-NoLogo --shell-arg=-Command" } else { "just" }

DENO_RUNTIME_VERSION := "2.5.0"

[private]
@default:
    just --list

[private]
@check-runtime:
    $versionOutput = @(deno --version); if (-not $?) { exit 1 }; $runtimeVersion = ($versionOutput[0] -split '\s+')[1]; if ($runtimeVersion -ne '{{ DENO_RUNTIME_VERSION }}') { Write-Warning "Local Deno $runtimeVersion does not match portable Deno {{ DENO_RUNTIME_VERSION }}. To align versions, run: deno upgrade --version {{ DENO_RUNTIME_VERSION }}" }

@fmt: check-runtime
    deno fmt

@lint: check-runtime
    deno lint

@check: check-runtime
    deno check src tests

@test: check-runtime
    deno test

[private]
@lock: check-runtime
    deno cache --lock=deno.lock src/install.ts

verify:
    {{ JUST_RUNNER }} fmt
    {{ JUST_RUNNER }} lint
    {{ JUST_RUNNER }} check
    {{ JUST_RUNNER }} test
    {{ JUST_RUNNER }} lock

@clean:
    echo "Cleaning up build artifacts..."
    if (Test-Path dist) { Remove-Item dist -Recurse -Force }
    if (Test-Path downloads) { Remove-Item downloads -Recurse -Force }
    if (Test-Path install) { Remove-Item install -Recurse -Force }

[private]
@compile: check-runtime clean
    New-Item -ItemType Directory install -Force | Out-Null
    deno compile --allow-all --output install/installer.exe src/install.ts

[private]
@hash-exe: compile
    Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop; (Get-FileHash install/installer.exe -Algorithm SHA256).Hash | Out-File install/installer.exe.sha256 -Encoding ASCII

[arg('platform', pattern='windows|linux')]
[arg('skip_verify', pattern='true|false')]
[private]
@release-exe platform skip_verify='false':
    if ('{{ skip_verify }}' -ne 'true') { {{ JUST_RUNNER }} verify; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
    {{ JUST_RUNNER }} hash-exe
    Copy-Item resources/install-exe.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

[private]
@vendor: check-runtime
    deno cache --vendor src/install.ts

[private]
@download-runtime:
    echo "Downloading Deno runtime version {{ DENO_RUNTIME_VERSION }}..."
    New-Item -ItemType Directory downloads -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/denoland/deno/releases/download/v{{ DENO_RUNTIME_VERSION }}/deno-x86_64-pc-windows-msvc.zip" -OutFile downloads/deno.zip

[private]
@extract-runtime: download-runtime
    echo "Extracting Deno runtime..."
    Expand-Archive downloads/deno.zip downloads -Force

[private]
@portable: clean vendor extract-runtime
    New-Item -ItemType Directory dist -Force | Out-Null
    Copy-Item downloads/deno.exe dist/
    Copy-Item src dist/src -Recurse
    if (Test-Path vendor) { Copy-Item vendor dist/vendor -Recurse }
    Copy-Item deno.lock dist/

[private]
@zip: portable
    New-Item -ItemType Directory install -Force | Out-Null
    Compress-Archive dist/* install/install-src.zip

[private]
@hash-zip: zip
    Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop; (Get-FileHash install/install-src.zip -Algorithm SHA256).Hash | Out-File install/install-src.zip.sha256 -Encoding ASCII

[arg('platform', pattern='windows|linux')]
[arg('skip_verify', pattern='true|false')]
[private]
@release-zip platform skip_verify='false':
    if ('{{ skip_verify }}' -ne 'true') { {{ JUST_RUNNER }} verify; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
    {{ JUST_RUNNER }} hash-zip
    Copy-Item resources/install-zip.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

[arg('format', pattern='zip|exe')]
[arg('platform', pattern='windows|linux')]
[arg('skip_verify', long='skip-verify', value='true')]
@release format platform skip_verify='false':
    {{ JUST_RUNNER }} release-{{ format }} {{ platform }} {{ skip_verify }}

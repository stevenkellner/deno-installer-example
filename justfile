
set shell := ["powershell.exe", "-NoLogo", "-Command"]

DENO_RUNTIME_VERSION := "2.5.0"

[private]
@default:
    just --list

@fmt:
    deno fmt

@lint:
    deno lint

@check:
    deno check src tests

@test:
    deno test

[private]
@lock:
    deno cache --lock=deno.lock src/install.ts

verify:
    just fmt
    just lint
    just check
    just test
    just lock

@clean:
    echo "Cleaning up build artifacts..."
    if (Test-Path dist) { Remove-Item dist -Recurse -Force }
    if (Test-Path downloads) { Remove-Item downloads -Recurse -Force }
    if (Test-Path install) { Remove-Item install -Recurse -Force }

[private]
@compile: clean
    New-Item -ItemType Directory install -Force | Out-Null
    deno compile --allow-all --output install/installer.exe src/install.ts

[private]
@hash-exe: compile
    (Get-FileHash install/installer.exe -Algorithm SHA256).Hash | Out-File install/installer.exe.sha256 -Encoding ASCII

[private]
[arg('platform', pattern='windows|linux')]
@release-exe platform:
    just verify
    just hash-exe
    Copy-Item resources/install-exe.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

[private]
@vendor:
    deno cache --vendor src/install.ts

[private]
@download-runtime:
    echo "Downloading Deno runtime version {{DENO_RUNTIME_VERSION}}..."
    New-Item -ItemType Directory downloads -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/denoland/deno/releases/download/v{{DENO_RUNTIME_VERSION}}/deno-x86_64-pc-windows-msvc.zip" -OutFile downloads/deno.zip

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
    (Get-FileHash install/install-src.zip -Algorithm SHA256).Hash | Out-File install/install-src.zip.sha256 -Encoding ASCII

[private]
[arg('platform', pattern='windows|linux')]
@release-zip platform:
    just verify
    just hash-zip
    Copy-Item resources/install-zip.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

[arg('format', pattern='zip|exe')]
[arg('platform', pattern='windows|linux')]
@release format platform:
    just release-{{format}} {{platform}}

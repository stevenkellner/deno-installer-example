
set shell := ["powershell.exe", "-NoLogo", "-Command"]

DENO_RUNTIME_VERSION := "2.5.0"

default:
    @just --list

fmt:
    @deno fmt

lint:
    @deno lint

check:
    @deno check src tests

test:
    @deno test

lock:
    @deno cache --lock=deno.lock --lock-write src/install.ts

verify:
    just fmt
    just lint
    just check
    just test
    just lock

clean:
    if (Test-Path dist) { Remove-Item dist -Recurse -Force }
    if (Test-Path downloads) { Remove-Item downloads -Recurse -Force }
    if (Test-Path dist.zip) { Remove-Item dist.zip -Force }

vendor:
    @deno vendor src/install.ts

download-runtime:
    New-Item -ItemType Directory downloads -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/denoland/deno/releases/download/v{{DENO_RUNTIME_VERSION}}/deno-x86_64-pc-windows-msvc.zip" -OutFile downloads/deno.zip

extract-runtime: download-runtime
    Expand-Archive downloads/deno.zip downloads/runtime -Force

compile:
    New-Item -ItemType Directory dist -Force | Out-Null
    @deno compile --allow-all --output dist/install.exe src/install.ts

hash-exe: compile
    $hash = (Get-FileHash dist/install.exe -Algorithm SHA256).Hash
    Set-Content dist/install.exe.sha256 $hash

release-exe:
    just verify
    just hash-exe

portable: vendor extract-runtime
    New-Item -ItemType Directory dist -Force | Out-Null
    Copy-Item downloads/runtime/deno.exe dist/
    $hash = (Get-FileHash dist/deno.exe -Algorithm SHA256).Hash; Set-Content dist/deno.sha256 $hash
    Copy-Item src dist/src -Recurse
    Copy-Item vendor dist/vendor -Recurse
    Copy-Item deno.lock dist/
    Copy-Item resources/install.ps1 dist/
    Copy-Item resources/install.sh dist/

zip: portable
    Compress-Archive dist/* dist.zip

hash-zip: zip
    $hash = (Get-FileHash dist.zip -Algorithm SHA256).Hash
    Set-Content dist.zip.sha256 $hash

release-zip:
    just verify
    just hash-zip

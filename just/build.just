# Removes generated build, download, and install files.
clean:
    echo "Cleaning up build artifacts..."
    if (Test-Path dist) { Remove-Item dist -Recurse -Force }
    if (Test-Path downloads) { Remove-Item downloads -Recurse -Force }
    if (Test-Path install) { Remove-Item install -Recurse -Force }

# Compiles the installer TypeScript into install/installer.exe.
[private]
@compile: check-runtime clean
    New-Item -ItemType Directory install -Force | Out-Null
    deno compile --allow-all --output install/installer.exe src/install.ts

# Writes the SHA-256 sidecar for the compiled installer executable.
[private]
@hash-exe: compile
    Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop; (Get-FileHash install/installer.exe -Algorithm SHA256).Hash | Out-File install/installer.exe.sha256 -Encoding ASCII

# Vendors dependencies used by the installer entry point.
[private]
@vendor: check-runtime
    deno cache --vendor src/install.ts

# Downloads the pinned Windows Deno runtime archive.
[private]
@download-runtime:
    echo "Downloading Deno runtime version {{ DENO_RUNTIME_VERSION }}..."
    New-Item -ItemType Directory downloads -Force | Out-Null
    Invoke-WebRequest -Uri "https://github.com/denoland/deno/releases/download/v{{ DENO_RUNTIME_VERSION }}/deno-x86_64-pc-windows-msvc.zip" -OutFile downloads/deno.zip

# Extracts the downloaded Deno executable into downloads/.
[private]
@extract-runtime: download-runtime
    echo "Extracting Deno runtime..."
    Expand-Archive downloads/deno.zip downloads -Force

# Stages a portable installer tree in dist/.
[private]
@portable: clean vendor extract-runtime
    New-Item -ItemType Directory dist -Force | Out-Null
    Copy-Item downloads/deno.exe dist/
    Copy-Item src dist/src -Recurse
    if (Test-Path vendor) { Copy-Item vendor dist/vendor -Recurse }
    Copy-Item deno.lock dist/

# Archives the portable tree as install/install-src.zip.
[private]
@zip: portable
    New-Item -ItemType Directory install -Force | Out-Null
    Compress-Archive dist/* install/install-src.zip

# Writes the SHA-256 sidecar for the portable ZIP archive.
[private]
@hash-zip: zip
    Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop; (Get-FileHash install/install-src.zip -Algorithm SHA256).Hash | Out-File install/install-src.zip.sha256 -Encoding ASCII

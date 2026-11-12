# Builds an EXE release and selects its Windows or shell launcher.
[arg('platform', pattern='windows|linux', help='Select the install.ps1 or install.sh launcher.')]
[arg('skip_verify', pattern='true|false', help='Skip verification when true.')]
[private]
@release-exe platform skip_verify='false':
    if ('{{ skip_verify }}' -ne 'true') { {{ JUST_RUNNER }} verify; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
    {{ JUST_RUNNER }} hash-exe
    Copy-Item resources/install-exe.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

# Builds a ZIP release and selects its Windows or shell launcher.
[arg('platform', pattern='windows|linux', help='Select the install.ps1 or install.sh launcher.')]
[arg('skip_verify', pattern='true|false', help='Skip verification when true.')]
[private]
@release-zip platform skip_verify='false':
    if ('{{ skip_verify }}' -ne 'true') { {{ JUST_RUNNER }} verify; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
    {{ JUST_RUNNER }} hash-zip
    Copy-Item resources/install-zip.{{ if platform == "windows" { "ps1" } else { "sh" } }} install/install.{{ if platform == "windows" { "ps1" } else { "sh" } }}

# Builds the requested release format and launcher; --skip-verify skips repeated checks.
[arg('format', pattern='zip|exe', help='Release artifact format: exe or zip.')]
[arg('platform', pattern='windows|linux', help='Launcher script to include: PowerShell or shell.')]
[arg('skip_verify', long='skip-verify', value='true', help='Skip checks already run by CI.')]
release format platform skip_verify='false':
    {{ JUST_RUNNER }} release-{{ format }} {{ platform }} {{ skip_verify }}

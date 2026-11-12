# Checks the installed Deno version and warns when it differs from the pinned runtime.
[private]
@check-runtime:
    $versionOutput = @(deno --version); \
    if (-not $?) { exit 1 }; \
    $runtimeVersion = ($versionOutput[0] -split '\s+')[1]; \
    if ($runtimeVersion -ne '{{ DENO_RUNTIME_VERSION }}') { \
        Write-Warning "Local Deno $runtimeVersion does not match portable Deno {{ DENO_RUNTIME_VERSION }}. To align versions, run: deno upgrade --version {{ DENO_RUNTIME_VERSION }}" ; \
    }

# Formats the Deno project files.
@fmt: check-runtime
    deno fmt

# Runs Deno lint checks.
@lint: check-runtime
    deno lint

# Type-checks the source and test modules.
@check: check-runtime
    deno check src tests

# Runs the Deno test suite.
@test: check-runtime
    deno test

# Updates the dependency lockfile for the installer entry point.
[private]
@lock: check-runtime
    deno cache --lock=deno.lock src/install.ts

# Runs formatting, lint, type-check, tests, and lockfile generation.
verify:
    {{ JUST_RUNNER }} fmt
    {{ JUST_RUNNER }} lint
    {{ JUST_RUNNER }} check
    {{ JUST_RUNNER }} test
    {{ JUST_RUNNER }} lock

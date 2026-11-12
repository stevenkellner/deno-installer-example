# Deno Installer Example

## Prerequisites

These commands are written for Windows PowerShell. Install Deno and the `just`
command runner:

```powershell
irm https://deno.land/install.ps1 | iex
winget install --id Casey.Just --exact
```

The `justfile` is already included in this repository; you do not need to
download it separately. Open a new PowerShell window after installing, then
check that both commands are available:

```powershell
deno --version
just --version
```

## Run

From the repository directory, run the demo directly with Deno:

```powershell
deno run --allow-all src/install.ts
```

Or run `just` to list the available project commands. For example, `just verify`
runs formatting, linting, type checking, tests, and updates the lockfile.

To download and extract the pinned Deno 2.5.0 Windows runtime used by the
portable build, run:

```powershell
just extract-runtime
```

The runtime is downloaded to `downloads/` and extracted under
`downloads/runtime/`.

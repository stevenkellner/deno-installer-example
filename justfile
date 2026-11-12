
set shell := ["powershell.exe", "-NoLogo", "-Command"]

CI_SHELL := env_var_or_default("CI_SHELL", "powershell.exe")
JUST_RUNNER := if CI_SHELL == "pwsh" { "just --shell pwsh --shell-arg=-NoLogo --shell-arg=-Command" } else { "just" }
DENO_RUNTIME_VERSION := "2.5.0"

import 'just/checks.just'
import 'just/build.just'
import 'just/release.just'

# Lists the available public project commands.
[default]
[private]
@default:
    just --list

#!/usr/bin/env sh
# Verify installer.exe beside this launcher, then forward arguments and exit status.
# Requires sha256sum or shasum and a shell capable of running Windows executables.
# Usage: sh install/install.sh [installer arguments...]
# The checksum sidecar must come from a trusted source; it is not a signature.
set -eu

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

calculate_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        checksum_output=$(sha256sum "$1")
    elif command -v shasum >/dev/null 2>&1; then
        checksum_output=$(shasum -a 256 "$1")
    else
        fail 'SHA-256 verification requires sha256sum or shasum.'
    fi
    printf '%s\n' "${checksum_output%% *}"
}

verify_hash() {
    [ -f "$1" ] || fail "Installer not found: $1"
    [ -f "$1.sha256" ] || fail "Checksum file not found: $1.sha256"
    # Normalize Windows line endings and uppercase hex written by PowerShell.
    expected_hash=$(tr -d '\r\n' < "$1.sha256" | tr '[:upper:]' '[:lower:]')
    [ "${#expected_hash}" -eq 64 ] || fail "Invalid SHA-256 checksum file: $1.sha256"
    case "$expected_hash" in
        *[!0-9a-f]*) fail "Invalid SHA-256 checksum file: $1.sha256" ;;
    esac
    actual_hash=$(calculate_sha256 "$1")
    [ "$actual_hash" = "$expected_hash" ] || fail "SHA-256 mismatch. Execution refused: $1"
}

run_installer() {
    exec "$@"
}

directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
executable="$directory/installer.exe"
verify_hash "$executable"
run_installer "$executable" "$@"

#!/usr/bin/env sh
# Verify install-src.zip, extract beside the launcher, and run its bundled runtime.
# Requires unzip, sha256sum or shasum, and Windows executable support (e.g. Git Bash).
# Usage: sh install/install.sh [installer arguments...]
# Extraction overwrites existing files and retains them. Trust the checksum source.
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
    [ -f "$1" ] || fail "Archive not found: $1"
    [ -f "$1.sha256" ] || fail "Checksum file not found: $1.sha256"
    # Normalize Windows line endings and uppercase hex written by PowerShell.
    expected_hash=$(tr -d '\r\n' < "$1.sha256" | tr '[:upper:]' '[:lower:]')
    [ "${#expected_hash}" -eq 64 ] || fail "Invalid SHA-256 checksum file: $1.sha256"
    case "$expected_hash" in
        *[!0-9a-f]*) fail "Invalid SHA-256 checksum file: $1.sha256" ;;
    esac
    actual_hash=$(calculate_sha256 "$1")
    [ "$actual_hash" = "$expected_hash" ] || fail "SHA-256 mismatch. Extraction refused: $1"
}

extract_installer() {
    command -v unzip >/dev/null 2>&1 || fail 'ZIP extraction requires unzip.'
    unzip -oq "$1" -d "$2"
    [ -f "$2/deno.exe" ] && [ -f "$2/src/install.ts" ] ||
        fail 'Archive is missing the runtime or installer entry point.'
}

run_installer() {
    cd "$1"
    shift
    exec ./deno.exe run --allow-all src/install.ts "$@"
}

directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
archive="$directory/install-src.zip"
verify_hash "$archive"
extract_installer "$archive" "$directory"
run_installer "$directory" "$@"

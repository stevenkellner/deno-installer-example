#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runtime_path="$script_dir/deno"
hash_path="$script_dir/deno.sha256"

if [ ! -f "$runtime_path" ]; then
	echo "Deno runtime not found: $runtime_path" >&2
	exit 1
fi
if [ ! -f "$hash_path" ]; then
	echo "Deno runtime checksum not found: $hash_path" >&2
	exit 1
fi

expected_hash=$(tr -d '[:space:]' < "$hash_path" | tr '[:upper:]' '[:lower:]')
if [ "${#expected_hash}" -ne 64 ] || ! printf '%s' "$expected_hash" | grep -Eq '^[[:xdigit:]]{64}$'; then
	echo "Deno runtime checksum is invalid: $hash_path" >&2
	exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
	actual_hash=$(sha256sum "$runtime_path" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
elif command -v shasum >/dev/null 2>&1; then
	actual_hash=$(shasum -a 256 "$runtime_path" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
else
	echo "Neither sha256sum nor shasum is available to verify Deno." >&2
	exit 1
fi

if [ "$actual_hash" != "$expected_hash" ]; then
	echo "Deno runtime checksum mismatch: $runtime_path" >&2
	exit 1
fi

exec "$runtime_path" run --allow-all "$script_dir/src/install.ts"

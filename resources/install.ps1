$runtimePath = Join-Path $PSScriptRoot "deno.exe"
$hashPath = Join-Path $PSScriptRoot "deno.sha256"

if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) {
	throw "Deno runtime not found: $runtimePath"
}
if (-not (Test-Path -LiteralPath $hashPath -PathType Leaf)) {
	throw "Deno runtime checksum not found: $hashPath"
}

$expectedHash = (Get-Content -LiteralPath $hashPath -Raw).Trim()
if ($expectedHash -notmatch '\A[0-9a-fA-F]{64}\z') {
	throw "Deno runtime checksum is invalid: $hashPath"
}

$actualHash = (Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash
if (-not [string]::Equals($actualHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
	throw "Deno runtime checksum mismatch: $runtimePath"
}

& $runtimePath run --allow-all (Join-Path $PSScriptRoot "src/install.ts")
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

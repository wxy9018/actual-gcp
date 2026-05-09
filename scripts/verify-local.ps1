# Static checks that do not call GCP APIs (safe for CI / laptops).
# For disk-prep integration tests, use Linux: sudo bash tests/test-fs-prepare.sh
# or push to GitHub and rely on Actions.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "terraform fmt -check -recursive"
terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
  Write-Host "Run: terraform fmt -recursive" -ForegroundColor Yellow
  exit $LASTEXITCODE
}

Write-Host "terraform init -backend=false -input=false"
if ($args -contains "-Clean") {
  Remove-Item -Recurse -Force (Join-Path $RepoRoot ".terraform") -ErrorAction SilentlyContinue
}
terraform init -backend=false -input=false
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "terraform validate"
terraform validate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "verify-local: OK (add Linux or GitHub Actions for fs-prepare + shellcheck)"

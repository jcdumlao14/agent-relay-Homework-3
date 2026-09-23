$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AGENT RELAY - HOMEWORK 4 PHASE 1" -ForegroundColor Cyan
Write-Host " Observability Foundation" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Safety check
$branch = git branch --show-current

if ($branch -ne "homework-4") {
    Write-Host "SAFETY STOP: Current branch is $branch" -ForegroundColor Red
    Write-Host "Expected: homework-4" -ForegroundColor Red
    exit 1
}

$status = git status --porcelain

if ($status) {
    Write-Host "SAFETY STOP: Working tree is not clean." -ForegroundColor Red
    git status
    exit 1
}

Write-Host "[1/6] Git safety check PASSED" -ForegroundColor Green
Write-Host "      Branch: $branch"

# Create HW4 directories
$dirs = @(
    "observability",
    "incident-response",
    "incident-response\runbooks",
    "incident-response\incidents",
    "security-audit",
    "security-audit\runs",
    "docs"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Write-Host "[2/6] HW4 directory structure CREATED" -ForegroundColor Green

# Add OpenTelemetry dependencies
Write-Host "[3/6] Installing OpenTelemetry dependencies with uv..." -ForegroundColor Yellow

uv add `
    opentelemetry-api `
    opentelemetry-sdk `
    opentelemetry-distro `
    opentelemetry-exporter-otlp `
    opentelemetry-instrumentation-fastapi `
    opentelemetry-instrumentation-sqlalchemy

if ($LASTEXITCODE -ne 0) {
    throw "uv dependency installation failed."
}

Write-Host "[4/6] OpenTelemetry dependencies INSTALLED" -ForegroundColor Green

# Verify imports
Write-Host "[5/6] Verifying OpenTelemetry installation..." -ForegroundColor Yellow

python -c "import opentelemetry; import opentelemetry.sdk; import opentelemetry.exporter.otlp; import opentelemetry.instrumentation.fastapi; import opentelemetry.instrumentation.sqlalchemy; print('OpenTelemetry imports: OK')"

if ($LASTEXITCODE -ne 0) {
    throw "OpenTelemetry import verification failed."
}

# Existing regression tests
Write-Host "[6/6] Running existing regression tests..." -ForegroundColor Yellow

pytest -q

if ($LASTEXITCODE -ne 0) {
    throw "Regression tests failed. No Git commit will be created."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " HW4 PHASE 1 COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Branch: homework-4" -ForegroundColor Green
Write-Host "HW3 tag: hw3-complete (untouched)" -ForegroundColor Green
Write-Host "OpenTelemetry: installed" -ForegroundColor Green
Write-Host "Tests: passed" -ForegroundColor Green
Write-Host ""
Write-Host "NO Git commit was created." -ForegroundColor Yellow
Write-Host "NO Docker configuration was changed." -ForegroundColor Yellow
Write-Host ""

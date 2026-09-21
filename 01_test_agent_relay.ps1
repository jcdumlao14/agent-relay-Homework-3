$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AGENT RELAY HOMEWORK 3 - STEP 1" -ForegroundColor Cyan
Write-Host " SQLite Diagnostic + Test Runner" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$Root = (Get-Location).Path
$DbPath = Join-Path $Root "agent-relay.db"
$DbUrl = "sqlite:///$($DbPath.Replace('\','/'))"

Write-Host "[1/6] Project directory:" -ForegroundColor Yellow
Write-Host "      $Root"
Write-Host ""

Write-Host "[2/6] Checking Python..." -ForegroundColor Yellow
python --version
Write-Host ""

Write-Host "[3/6] Checking SQLite directly..." -ForegroundColor Yellow

if (Test-Path $DbPath -PathType Container) {
    Write-Host "ERROR: agent-relay.db exists as a DIRECTORY." -ForegroundColor Red
    Write-Host "Path: $DbPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Rename/remove that directory manually before continuing." -ForegroundColor Red
    exit 1
}

$SqliteTest = @"
import sqlite3
db = r'''$DbPath'''
conn = sqlite3.connect(db)
conn.execute("CREATE TABLE IF NOT EXISTS _startup_test (id INTEGER)")
conn.commit()
conn.close()
print("SQLite direct connection: OK")
"@

$SqliteTest | python

if (-not (Test-Path $DbPath)) {
    Write-Host "ERROR: SQLite database was not created." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/6] Checking database environment variables..." -ForegroundColor Yellow

Write-Host "RELAY_DATABASE_URL = $env:RELAY_DATABASE_URL"
Write-Host "DATABASE_URL       = $env:DATABASE_URL"
Write-Host ""

Write-Host "[5/6] Forcing Agent Relay tests to use:" -ForegroundColor Yellow
Write-Host "      $DbUrl"
Write-Host ""

$env:RELAY_DATABASE_URL = $DbUrl
$env:DATABASE_URL = ""

Write-Host "[6/6] Running pytest..." -ForegroundColor Yellow
Write-Host ""

uv run pytest -q

$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan

if ($ExitCode -eq 0) {
    Write-Host " SUCCESS: ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Agent Relay is ready for Q2." -ForegroundColor Green
} else {
    Write-Host " TESTS STILL FAIL" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The script preserved the source code." -ForegroundColor Yellow
    Write-Host "Paste the complete output into ChatGPT." -ForegroundColor Yellow
}

exit $ExitCode

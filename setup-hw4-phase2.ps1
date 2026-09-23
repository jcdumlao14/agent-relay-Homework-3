$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================"
Write-Host " AGENT RELAY - HW4 PHASE 2"
Write-Host " OpenTelemetry Instrumentation"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# 1. SAFETY CHECK
# ------------------------------------------------------------
$status = git status --porcelain |
    Where-Object { $_ -notmatch '\ssetup-hw4-phase2\.ps1$' }

if ($status) {
    Write-Host $status
    throw "SAFETY STOP: Working tree contains changes other than setup-hw4-phase2.ps1."
}

$branch = (git branch --show-current).Trim()

if ($branch -ne "homework-4") {
    throw "SAFETY STOP: Expected branch homework-4, found '$branch'."
}

Write-Host "[1/6] Git safety check PASSED"
Write-Host ""

# ------------------------------------------------------------
# 2. INSTALL LOGGING INSTRUMENTATION
# ------------------------------------------------------------
Write-Host "[2/6] Installing OpenTelemetry logging instrumentation..."

uv add "opentelemetry-instrumentation-logging>=0.65b0"

Write-Host "[2/6] Logging instrumentation INSTALLED"
Write-Host ""

# ------------------------------------------------------------
# 3. CREATE OBSERVABILITY MODULE
# ------------------------------------------------------------
Write-Host "[3/6] Creating observability.py..."

if (-not (Test-Path ".\observability.py")) {
    throw "SAFETY STOP: Validated observability.py is missing."
}

$observabilityContent = Get-Content ".\observability.py" -Raw

if (
    $observabilityContent -notmatch "agent_relay_http_requests_total" -or
    $observabilityContent -notmatch "agent_relay_claim_errors_total" -or
    $observabilityContent -notmatch "agent_relay_http_request_duration_ms"
) {
    throw "SAFETY STOP: observability.py does not contain the required metrics."
}

Set-Content -Path ".\observability.py" -Value $observabilityContent -Encoding UTF8

Write-Host "[3/6] observability.py CREATED"
Write-Host ""
 # 4. PATCH MAIN.PY SAFELY
# ------------------------------------------------------------
Write-Host "[4/6] Patching main.py..."

$mainPath = ".\main.py"
$content = Get-Content $mainPath -Raw

if ($content -match "from observability import configure_observability") {
    Write-Host "Observability import already present."
}
else {
    $anchor = "from sqlalchemy.exc import OperationalError"

    if (-not $content.Contains($anchor)) {
        throw "Could not find safe import anchor in main.py."
    }

    $content = $content.Replace(
        $anchor,
        "$anchor`nfrom observability import configure_observability"
    )
}

if ($content -match "configure_observability\(app\)") {
    Write-Host "Observability configuration already present."
}
else {
    $anchor = 'app = FastAPI(title="Agent Relay", version="0.1.0", lifespan=lifespan)'

    if (-not $content.Contains($anchor)) {
        throw "Could not find exact FastAPI app declaration."
    }

    $replacement = "$anchor`nconfigure_observability(app)"

    $content = $content.Replace(
        $anchor,
        $replacement
    )
}

Set-Content -Path $mainPath -Value $content -Encoding UTF8

Write-Host "[4/6] main.py PATCHED SAFELY"
Write-Host ""

# ------------------------------------------------------------
# 5. VALIDATE IMPORTS
# ------------------------------------------------------------
Write-Host "[5/6] Validating Python imports..."

uv run python -c "import observability; import main; print('OpenTelemetry module import: OK'); print('FastAPI application import: OK')"

Write-Host "[5/6] IMPORT VALIDATION PASSED"
Write-Host ""

# ------------------------------------------------------------
# 6. RUN REGRESSION TESTS
# ------------------------------------------------------------
Write-Host "[6/6] Running regression tests..."

uv run pytest -q

if ($LASTEXITCODE -ne 0) {
    throw "Regression tests failed."
}

Write-Host ""
Write-Host "============================================================"
Write-Host " HW4 PHASE 2 COMPLETE"
Write-Host "============================================================"
Write-Host ""
Write-Host "Created:"
Write-Host "  observability.py"
Write-Host ""
Write-Host "Modified:"
Write-Host "  main.py"
Write-Host "  pyproject.toml"
Write-Host "  uv.lock"
Write-Host ""
Write-Host "No commit was created."
Write-Host "No HW3 branch/tag was modified."
Write-Host ""

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AGENT RELAY HOMEWORK 3 - STEP 2" -ForegroundColor Cyan
Write-Host " Q2 Acceptance Scenario Analyzer" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Reading acceptance scenarios from SPEC.md..." -ForegroundColor Yellow
Write-Host ""

$spec = Get-Content .\SPEC.md -Raw

$start = $spec.IndexOf("## Acceptance scenarios")

if ($start -ge 0) {
    $remaining = $spec.Substring($start)
    $next = $remaining.IndexOf("`n## ", 5)

    if ($next -gt 0) {
        $acceptance = $remaining.Substring(0, $next)
    } else {
        $acceptance = $remaining
    }

    Write-Host $acceptance
} else {
    Write-Host "Acceptance section not found." -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[2/4] Detecting API routes from main.py..." -ForegroundColor Yellow
Write-Host ""

Select-String -Path .\main.py -Pattern '@app\.(get|post|put|patch|delete|websocket)' |
    ForEach-Object {
        Write-Host $_.Line.Trim()
    }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[3/4] Detecting route decorators in all Python files..." -ForegroundColor Yellow
Write-Host ""

Get-ChildItem -Filter *.py | ForEach-Object {
    $file = $_
    Select-String -Path $file.FullName `
        -Pattern '@(app|router)\.(get|post|put|patch|delete|websocket)' |
        ForEach-Object {
            Write-Host ("{0}: {1}" -f $file.Name, $_.Line.Trim())
        }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[4/4] Checking current Git status..." -ForegroundColor Yellow
Write-Host ""

git status --short

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " STEP 2 ANALYSIS COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "No source files were modified." -ForegroundColor Green
Write-Host "Paste the output into ChatGPT so we can generate the" -ForegroundColor Green
Write-Host "exact Q2 integration test from the starter API." -ForegroundColor Green
Write-Host ""

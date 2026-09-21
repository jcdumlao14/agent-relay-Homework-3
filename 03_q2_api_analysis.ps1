$ErrorActionPreference = "Stop"

$Output = ".\q2_api_analysis.txt"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AGENT RELAY HOMEWORK 3 - Q2 API ANALYSIS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

"============================================================" | Set-Content $Output
"AGENT RELAY Q2 API ANALYSIS" | Add-Content $Output
"Generated: $(Get-Date)" | Add-Content $Output
"============================================================" | Add-Content $Output
"" | Add-Content $Output

"================ ACCEPTANCE SCENARIOS ================" | Add-Content $Output
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

    $acceptance | Add-Content $Output
} else {
    "Acceptance section not found." | Add-Content $Output
}

"" | Add-Content $Output
"================ MAIN.PY ROUTES ================" | Add-Content $Output

Select-String -Path .\main.py `
    -Pattern '@app\.(get|post|put|patch|delete|websocket)' |
    ForEach-Object {
        $_.Line.Trim() | Add-Content $Output
    }

"" | Add-Content $Output
"================ ALL ROUTES ================" | Add-Content $Output

Get-ChildItem -Filter *.py | ForEach-Object {
    $file = $_

    Select-String -Path $file.FullName `
        -Pattern '@(app|router)\.(get|post|put|patch|delete|websocket)' |
        ForEach-Object {
            ("{0}: {1}" -f $file.Name, $_.Line.Trim()) | Add-Content $Output
        }
}

"" | Add-Content $Output
"================ REQUEST/RESPONSE MODELS ================" | Add-Content $Output

Select-String -Path .\schemas.py `
    -Pattern '^class |BaseModel|Field\(' |
    ForEach-Object {
        $_.Line.Trim() | Add-Content $Output
    }

"" | Add-Content $Output
"================ AUTH / TOKEN REFERENCES ================" | Add-Content $Output

Select-String -Path .\main.py,.\storage.py,.\worker.py `
    -Pattern 'token|authorization|Authorization|Bearer' |
    ForEach-Object {
        ("{0}:{1}: {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim()) | Add-Content $Output
    }

Write-Host "Analysis saved to:" -ForegroundColor Green
Write-Host (Resolve-Path $Output).Path -ForegroundColor White
Write-Host ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " COMPLETE Q2 ANALYSIS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Get-Content $Output

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " No source files were modified." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

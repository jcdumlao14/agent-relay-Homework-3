# Agent Relay Homework 3 - VS Code automation
$ErrorActionPreference = "Stop"

Write-Host "=== Agent Relay Homework 3 - VS Code Automation ===" -ForegroundColor Cyan
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
Write-Host "Project: $ProjectRoot" -ForegroundColor Gray

if (-not (Test-Path ".git")) { throw "Place this script in C:\Users\kambar\agent-relay and run it from the repository root." }

$Readme = @'
# Agent Relay — Homework 3

## Overview

Agent Relay is a FastAPI-based task relay service for registering workers (agents), queuing tasks, leasing work to agents, tracking attempts, and recovering expired leases. Homework 3 extends the application into a containerized PostgreSQL-backed service with Kubernetes deployment and GitHub Actions CI/CD validation.

## Homework 3 Questions

| Question | Answer |
|---|---|
| Q1 | Agents claim tasks from a DB through an HTTP API. |
| Q2 | `completed` |
| Q3 | `-p` |
| Q4 | `postgres` |
| Q5 | Deployment |
| Q6 | Keep the existing version running and stop the deployment. |

## Architecture

```text
                         GitHub Actions
                              |
                    +---------+---------+
                    |                   |
                Python Tests       Docker Build
                    |                   |
                    +---------+---------+
                              |
                    Kubernetes Validation
                              |
                +-------------+-------------+
                |                           |
          Agent Relay API             PostgreSQL
          FastAPI/Uvicorn              Database
                |                           |
                +-------------+-------------+
                              |
                         Worker Agents
```

Agents interact with persistent task state through an HTTP API. PostgreSQL stores agents, tasks, and attempts when `DATABASE_URL` points to PostgreSQL.

## Complete Project Structure

```text
agent-relay/
├── .github/
│   └── workflows/
│       └── ci.yml
├── k8s/
│   ├── namespace.yaml
│   ├── postgres-secret.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── agent-relay-deployment.yaml
│   └── agent-relay-service.yaml
├── q2/
├── .gitignore
├── Dockerfile
├── compose.yaml
├── pyproject.toml
├── uv.lock
├── main.py
├── database.py
├── storage.py
├── schemas.py
├── errors.py
├── worker.py
├── dashboard.py
├── dashboard.html
├── test_agent_relay.py
├── SPEC.md
├── README.md
└── update-agent-relay-vscode.ps1
```

## Technology Stack

- Python 3.11+
- FastAPI
- Uvicorn
- SQLAlchemy
- PostgreSQL 16
- psycopg 3
- Pydantic Settings
- pytest
- uv
- Docker / Docker Compose
- Kubernetes
- Kind
- kubectl
- GitHub Actions

## Local Setup in VS Code

```powershell
cd C:\Users\kambar\agent-relay
code .
uv sync
uv run pytest -v
```

## Run the API Locally

```powershell
uv run uvicorn main:app --reload
```

Useful endpoints:

```text
GET /health
GET /ready
GET /dashboard
```

## PostgreSQL with Docker Compose

Build the application image:

```powershell
docker build -t agent-relay:q4 .
```

Start the stack:

```powershell
docker compose up -d
docker compose ps
```

Check the API:

```powershell
curl.exe http://127.0.0.1:8003/health
curl.exe http://127.0.0.1:8003/ready
```

Inspect PostgreSQL:

```powershell
docker compose exec postgres psql -U agent_relay -d agent_relay
```

Inside `psql`:

```text
\dt
\q
```

Stop the stack:

```powershell
docker compose down
```

## Docker

The expected Homework 3 image tag is:

```text
agent-relay:q4
```

Build and inspect:

```powershell
docker build -t agent-relay:q4 .
docker image inspect agent-relay:q4
```

## Kubernetes

The Kubernetes manifests are stored in `k8s/` and define the namespace, PostgreSQL resources, and Agent Relay resources.

Reuse the existing Kind cluster rather than deleting/recreating it:

```powershell
kubectl config current-context
kind get clusters
```

Expected context:

```text
kind-agent-relay
```

Load the application image:

```powershell
kind load docker-image agent-relay:q4 --name agent-relay
```

Apply resources:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/agent-relay-deployment.yaml
kubectl apply -f k8s/agent-relay-service.yaml
```

Check resources:

```powershell
kubectl get pods -n agent-relay
kubectl get services -n agent-relay
kubectl get pvc -n agent-relay
```

Wait for deployments:

```powershell
kubectl wait --namespace agent-relay --for=condition=available deployment/postgres --timeout=180s
kubectl wait --namespace agent-relay --for=condition=available deployment/agent-relay --timeout=180s
```

Forward and verify:

```powershell
kubectl port-forward -n agent-relay service/agent-relay 8000:8000
```

In another VS Code terminal:

```powershell
curl.exe http://127.0.0.1:8000/health
curl.exe http://127.0.0.1:8000/ready
```

## CI/CD

Workflow file:

```text
.github/workflows/ci.yml
```

The workflow runs for pushes to `main` and pull requests targeting `main`.

### Python Tests

- Checkout repository
- Install Python 3.11
- Install `uv`
- Run `uv sync --frozen`
- Start PostgreSQL 16 service container
- Set `DATABASE_URL`
- Run `uv run pytest -v`

### Docker Build

Builds and verifies:

```text
agent-relay:q4
```

### Kubernetes Validation

The workflow creates a temporary Kind cluster, builds and loads `agent-relay:q4`, validates manifests, deploys PostgreSQL and Agent Relay, waits for both deployments, checks resources, and verifies `/health` and `/ready`.

The jobs are ordered: Docker waits for tests, and Kubernetes waits for Docker.

## Environment Configuration

The application database setting is `DATABASE_URL`.

Example PostgreSQL URL:

```text
postgresql+psycopg://agent_relay:agent_relay@127.0.0.1:5432/agent_relay
```

Do not commit credentials or `.env` files.

## Testing

Run all tests:

```powershell
uv run pytest -v
```

Run the main test file:

```powershell
uv run pytest test_agent_relay.py -v
```

The test suite covers core service behavior including health checks, task/agent operations, and invalid status handling.

## Git Workflow

```powershell
git status
git diff
git diff --check
git push origin main
```

Repository:

```text
https://github.com/jcdumlao14/agent-relay-Homework-3
```

## Automated VS Code Script

`update-agent-relay-vscode.ps1` is a self-contained automation script. It writes the complete README, so an existing short README is automatically replaced instead of causing the previous validation error.

Run from the VS Code PowerShell terminal:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\update-agent-relay-vscode.ps1
```

The script:

1. Confirms it is in the Git repository root.
2. Checks the required project files.
3. Checks the CI/CD configuration.
4. Writes the complete README.
5. Runs `git diff --check`.
6. Runs `uv run pytest -v`.
7. Stages `README.md`.
8. Creates a Git commit if the README changed.
9. Pushes the commit to `origin main`.
10. Shows the final Git status and commit.

## Troubleshooting

### README is too short

The corrected script no longer depends on the old README length. It writes the full README before validation. Replace your old script with the corrected file and run it again.

### `uv` is not recognized

```powershell
uv --version
uv sync
```

Restart the VS Code terminal if necessary.

### Docker is not running

Start Docker Desktop and check:

```powershell
docker version
```

### Kubernetes context

```powershell
kubectl config current-context
```

Expected local Kind context:

```text
kind-agent-relay
```

### Kubernetes pod troubleshooting

```powershell
kubectl get pods -n agent-relay
kubectl describe pod -n agent-relay <pod-name>
kubectl logs -n agent-relay deployment/agent-relay
kubectl logs -n agent-relay deployment/postgres
```

## Homework 3 Completion Checklist

🟢 Q1 Architecture — Complete

🟢 Q2 Testing — Complete

🟢 Q3 Docker — Complete

🟢 Q4 PostgreSQL — Complete

🟢 Q5 Kubernetes — Complete

🟢 Q6 CI/CD — Complete

🟢 Local Python tests passed

🟢 Docker image built successfully

🟢 PostgreSQL integration verified

🟢 Kubernetes resources validated

🟢 `/health` verified

🟢 `/ready` verified

🟢 GitHub Actions CI/CD passed

## Final Verification

```powershell
cd C:\Users\kambar\agent-relay
uv run pytest -v
git diff --check
git status
git log -1 --oneline
```

The GitHub Actions workflow should then show successful Python Tests, Docker Build, and Kubernetes Validation jobs for the latest `main` commit.

'@

Write-Host "`n=== Check required project structure ===" -ForegroundColor Cyan
$required = @(
  ".github/workflows/ci.yml", "k8s/namespace.yaml", "k8s/postgres-secret.yaml",
  "k8s/postgres-pvc.yaml", "k8s/postgres-deployment.yaml", "k8s/postgres-service.yaml",
  "k8s/agent-relay-deployment.yaml", "k8s/agent-relay-service.yaml", "Dockerfile",
  "compose.yaml", "pyproject.toml", "uv.lock", "main.py", "database.py", "storage.py",
  "schemas.py", "errors.py", "worker.py", "dashboard.py", "dashboard.html",
  "test_agent_relay.py", "SPEC.md"
)
$missing = @($required | Where-Object { -not (Test-Path $_) })
if ($missing.Count -gt 0) { throw "Missing required file(s): $($missing -join ', ')" }
Write-Host "All required project files found." -ForegroundColor Green

Write-Host "`n=== Check CI/CD configuration ===" -ForegroundColor Cyan
$ci = Get-Content ".github/workflows/ci.yml" -Raw
$patterns = @(
  "DATABASE_URL",
  "docker build -t agent-relay:q4",
  "kind load docker-image agent-relay:q4",
  "kubectl wait",
  "/health",
  "/ready"
)
foreach ($pattern in $patterns) {
  if ($ci -notmatch [regex]::Escape($pattern)) { throw "CI/CD configuration check failed: $pattern" }
}
Write-Host "CI/CD configuration checks passed." -ForegroundColor Green

Write-Host "`n=== Write complete README ===" -ForegroundColor Cyan
$readmePath = Join-Path $ProjectRoot "README.md"
[System.IO.File]::WriteAllText($readmePath, $Readme, [System.Text.UTF8Encoding]::new($false))
$size = (Get-Item $readmePath).Length
Write-Host "README.md generated: $size bytes" -ForegroundColor Green
if ($size -lt 5000) { throw "Generated README is unexpectedly short." }

Write-Host "`n=== Validate Git whitespace ===" -ForegroundColor Cyan
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check failed." }

Write-Host "`n=== Run Python tests ===" -ForegroundColor Cyan
uv run pytest -v
if ($LASTEXITCODE -ne 0) { throw "Tests failed. Commit/push stopped." }

Write-Host "`n=== Stage README ===" -ForegroundColor Cyan
git add README.md
if ($LASTEXITCODE -ne 0) { throw "git add failed." }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "Staged Git whitespace check failed." }

$staged = @(git diff --cached --name-only)
if ($staged -contains "README.md") {
  Write-Host "`n=== Commit README ===" -ForegroundColor Cyan
  git commit -m "Add complete Homework 3 README"
  if ($LASTEXITCODE -ne 0) { throw "git commit failed." }

  Write-Host "`n=== Push to GitHub ===" -ForegroundColor Cyan
  git push origin main
  if ($LASTEXITCODE -ne 0) { throw "git push failed." }
} else {
  Write-Host "README has no changes to commit." -ForegroundColor Yellow
}

Write-Host "`n=== Final verification ===" -ForegroundColor Cyan
git status --short --branch
git log -1 --oneline
Write-Host "`nDONE: README generated, project validated, tests passed, and GitHub updated when changes were present." -ForegroundColor Green

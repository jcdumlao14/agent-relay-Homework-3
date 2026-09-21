# Agent Relay - Homework 3

## Overview

Agent Relay is a FastAPI task relay service for registering worker agents, queuing tasks, leasing work, tracking attempts, and recovering expired leases. Homework 3 extends the application with PostgreSQL, Docker, Kubernetes, and GitHub Actions CI/CD.

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
      +-- Python Tests
      |
      +-- Docker Build
      |
      +-- Kubernetes Validation
                |
        +-------+-------+
        |               |
   Agent Relay      PostgreSQL
   FastAPI API       Database
        |
    Worker Agents
```

Agents interact with persistent task state through the HTTP API. PostgreSQL stores agents, tasks, and attempts when `DATABASE_URL` points to PostgreSQL.

## Complete Project Structure

```text
agent-relay/
|-- .github/
|   `-- workflows/
|       `-- ci.yml
|-- k8s/
|   |-- namespace.yaml
|   |-- postgres-secret.yaml
|   |-- postgres-pvc.yaml
|   |-- postgres-deployment.yaml
|   |-- postgres-service.yaml
|   |-- agent-relay-deployment.yaml
|   `-- agent-relay-service.yaml
|-- q2/
|-- .gitignore
|-- Dockerfile
|-- compose.yaml
|-- pyproject.toml
|-- uv.lock
|-- main.py
|-- database.py
|-- storage.py
|-- schemas.py
|-- errors.py
|-- worker.py
|-- dashboard.py
|-- dashboard.html
|-- test_agent_relay.py
|-- SPEC.md
|-- README.md
`-- update-agent-relay-vscode-auto-replace.ps1
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
- Docker and Docker Compose
- Kubernetes
- Kind
- kubectl
- GitHub Actions

## Local Setup in VS Code

```powershell
cd C:\Users\kambar\agent-relay
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

The expected Homework 3 image tag is `agent-relay:q4`.

```powershell
docker build -t agent-relay:q4 .
docker image inspect agent-relay:q4
```

## Kubernetes

The Kubernetes manifests are stored in `k8s/`. Reuse the existing Kind cluster. Do not delete or recreate the working cluster.

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

Forward the API:

```powershell
kubectl port-forward -n agent-relay service/agent-relay 8000:8000
```

In another VS Code terminal:

```powershell
curl.exe http://127.0.0.1:8000/health
curl.exe http://127.0.0.1:8000/ready
```

## CI/CD

Workflow file: `.github/workflows/ci.yml`

The workflow runs on pushes to `main` and pull requests targeting `main`.

### Python Tests

- Checkout repository
- Install Python 3.11
- Install uv
- Run `uv sync --frozen`
- Start PostgreSQL 16 as a service container
- Set `DATABASE_URL`
- Run `uv run pytest -v`

### Docker Build

Builds and verifies `agent-relay:q4`.

### Kubernetes Validation

Creates a temporary Kind cluster, builds and loads `agent-relay:q4`, validates the manifests, deploys PostgreSQL and Agent Relay, waits for both deployments, checks resources, and verifies `/health` and `/ready`.

The jobs run in order: Docker waits for Python Tests, and Kubernetes waits for Docker Build.

## Environment Configuration

The application database configuration uses `DATABASE_URL`.

Example PostgreSQL connection string:

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

## Git Workflow

```powershell
git status
git diff
git diff --check
git log -1 --oneline
git push origin main
```

Repository: `https://github.com/jcdumlao14/agent-relay-Homework-3`

## VS Code Automation Script

`update-agent-relay-vscode-auto-replace.ps1` automatically backs up the existing README, replaces it with the clean Homework 3 README, validates it, runs tests, and commits and pushes the README when it changes.

Run from the VS Code PowerShell terminal:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\update-agent-relay-vscode-auto-replace.ps1
```

The script creates `README.before-auto-replace.md` as a backup before replacing the README.

## Homework 3 Completion

<span style="color:green">GREEN - Q1 Architecture - Complete</span>

<span style="color:green">GREEN - Q2 Testing - Complete</span>

<span style="color:green">GREEN - Q3 Docker - Complete</span>

<span style="color:green">GREEN - Q4 PostgreSQL - Complete</span>

<span style="color:green">GREEN - Q5 Kubernetes - Complete</span>

<span style="color:green">GREEN - Q6 CI/CD - Complete</span>

<span style="color:green">GREEN - Local Python tests passed</span>

<span style="color:green">GREEN - Docker image built successfully</span>

<span style="color:green">GREEN - PostgreSQL integration verified</span>

<span style="color:green">GREEN - Kubernetes resources validated</span>

<span style="color:green">GREEN - /health verified</span>

<span style="color:green">GREEN - /ready verified</span>

<span style="color:green">GREEN - GitHub Actions CI/CD passed</span>
## Final Verification

```powershell
cd C:\Users\kambar\agent-relay
uv run pytest -v
git diff --check
git status
git log -1 --oneline
```

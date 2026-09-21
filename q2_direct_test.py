import os
import sys
sys.path.insert(0, os.getcwd())

print("STARTING Q2...", flush=True)

from fastapi.testclient import TestClient
import main

print("APP IMPORTED", flush=True)

client = TestClient(main.app)

def show(label, r):
    print(f"\n[{label}] HTTP {r.status_code}", flush=True)
    print(r.text, flush=True)
    return r

print("\n1. Registering sender...", flush=True)
r = show("SENDER", client.post(
    "/api/v1/agents",
    json={
        "name": "q2-sender",
        "description": "Q2 acceptance sender"
    }
))

if r.status_code != 201:
    raise SystemExit("SENDER REGISTRATION FAILED")

sender = r.json()
sender_id = sender.get("id") or sender.get("agent_id")
sender_token = sender.get("token") or sender.get("agent_token")

print(f"Sender ID = {sender_id}", flush=True)

print("\n2. Registering recipient...", flush=True)
r = show("RECIPIENT", client.post(
    "/api/v1/agents",
    json={
        "name": "q2-recipient",
        "description": "Q2 acceptance recipient"
    }
))

if r.status_code != 201:
    raise SystemExit("RECIPIENT REGISTRATION FAILED")

recipient = r.json()
recipient_id = recipient.get("id") or recipient.get("agent_id")
recipient_token = recipient.get("token") or recipient.get("agent_token")

print(f"Recipient ID = {recipient_id}", flush=True)

print("\n3. Sender creating task...", flush=True)
r = show("CREATE TASK", client.post(
    "/api/v1/tasks",
    headers={"Authorization": f"Bearer {sender_token}"},
    json={
        "to": recipient_id,
        "input": "Q2 acceptance task: calculate 2 + 2"
    }
))

if r.status_code != 201:
    raise SystemExit("TASK CREATION FAILED")

task = r.json()
task_id = task.get("id") or task.get("task_id")

print(f"Task ID = {task_id}", flush=True)

print("\n4. Recipient claiming task...", flush=True)
r = show("CLAIM", client.post(
    "/api/v1/tasks/claim",
    headers={"Authorization": f"Bearer {recipient_token}"},
    json={
        "worker_id": "q2-worker",
        "wait_seconds": 0
    }
))

if r.status_code != 200:
    raise SystemExit("TASK CLAIM FAILED")

claimed = r.json()
claim_token = claimed.get("claim_token")

print(f"Claim token received = {bool(claim_token)}", flush=True)

print("\n5. Recipient completing task...", flush=True)
r = show("COMPLETE", client.post(
    f"/api/v1/tasks/{task_id}/complete",
    headers={"Authorization": f"Bearer {recipient_token}"},
    json={
        "claim_token": claim_token,
        "output": "4"
    }
))

if r.status_code != 200:
    raise SystemExit("TASK COMPLETION FAILED")

print("\n6. Sender reading result...", flush=True)
r = show("RESULT", client.get(
    f"/api/v1/tasks/{task_id}",
    headers={"Authorization": f"Bearer {sender_token}"}
))

if r.status_code != 200:
    raise SystemExit("RESULT RETRIEVAL FAILED")

result = r.json()
status = result.get("status")
output = result.get("output")

print("\n============================================================")
print("Q2 FINAL")
print("============================================================")
print(f"Task ID : {task_id}")
print(f"Status  : {status}")
print(f"Output  : {output}")
print("============================================================")

if status == "completed" and output == "4":
    print("\nQ2 ACCEPTANCE TEST: PASSED")
    print("Required Q2 answer: completed")
else:
    print("\nQ2 ACCEPTANCE TEST: FAILED")
    print(f"Expected status=completed and output=4")
    raise SystemExit(1)

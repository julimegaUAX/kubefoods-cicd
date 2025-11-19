#!/bin/bash

SERVICE_IP=$(minikube ip)
PORT=30080

echo "Haciendo health check…"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP:$PORT/health.html)

if [ "$STATUS" -eq 200 ]; then
  echo "OK ✔ (status 200)"
  exit 0
else
  echo "FALLO ❌ — Haciendo rollback"
  kubectl rollout undo deployment/kubefoods-backend
  exit 1
fi

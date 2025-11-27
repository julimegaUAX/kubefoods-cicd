#!/bin/bash

SERVICE_IP=$(minikube ip)
PORT=30080
MAX_RETRIES=10
RETRY_COUNT=0

echo "Haciendo health check…"

until [ $RETRY_COUNT -ge $MAX_RETRIES ]
do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP:$PORT/health.html)
    
    if [ "$STATUS" -eq 200 ]; then
        echo "OK ✔ (status 200)"
        echo "Health check exitoso después de $RETRY_COUNT intentos"
        exit 0
    fi
    
    echo "Intento $((RETRY_COUNT+1)) fallido (status: $STATUS). Reintentando en 5 segundos..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 5
done

echo "FALLO ❌ - No se pudo conectar después de $MAX_RETRIES intentos"

# Solo intentar rollback si hay revisiones anteriores
REVISION_COUNT=$(kubectl rollout history deployment/kubefoods-backend | grep -c "revision")
if [ "$REVISION_COUNT" -gt 1 ]; then
    echo "Intentando rollback…"
    kubectl rollout undo deployment/kubefoods-backend
    echo "Rollback completado ✔"
else
    echo "⚠️  No hay revisiones anteriores para hacer rollback"
fi

exit 1
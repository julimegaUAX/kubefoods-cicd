#!/bin/bash

set -e

SERVICE_IP=$(minikube ip)
PORT=30080
MAX_RETRIES=15
RETRY_COUNT=0

echo "=== Iniciando validación del despliegue ==="
echo "Service IP: $SERVICE_IP"
echo "Port: $PORT"

# Primero, verificar el estado del deployment
echo "📊 Estado del deployment:"
kubectl get deployment kubefoods-backend

echo "📋 Pods:"
kubectl get pods -l app=kubefoods

# Verificar si los pods están en estado CrashLoopBackOff o ImagePullBackOff
POD_STATUS=$(kubectl get pods -l app=kubefoods -o jsonpath='{.items[0].status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "Unknown")

if [[ "$POD_STATUS" == "ImagePullBackOff" || "$POD_STATUS" == "ErrImagePull" ]]; then
    echo "🚨 ERROR CRÍTICO: No se puede descargar la imagen - $POD_STATUS"
    echo "La imagen especificada no existe o no es accesible"
    
    # Ejecutar rollback inmediatamente
    execute_rollback
    exit 1
fi

if [[ "$POD_STATUS" == "CrashLoopBackOff" ]]; then
    echo "🚨 ERROR: Los pods están en CrashLoopBackOff"
fi

echo ""
echo "🔄 Realizando health checks..."

until [ $RETRY_COUNT -ge $MAX_RETRIES ]
do
    echo ""
    echo "Intento de health check $((RETRY_COUNT+1))/$MAX_RETRIES"
    
    # Verificar estado de los pods primero
    RUNNING_PODS=$(kubectl get pods -l app=kubefoods --field-selector=status.phase=Running --no-headers | wc -l)
    echo "Pods en estado Running: $RUNNING_PODS"
    
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP:$PORT/health.html || echo "000")
    RESPONSE=$(curl -s http://$SERVICE_IP:$PORT/health.html 2>/dev/null || echo "Connection failed")
    
    echo "Status HTTP: $STATUS"
    echo "Response: $RESPONSE"
    
    if [ "$STATUS" -eq 200 ]; then
        echo "✅ HEALTH CHECK EXITOSO (status 200)"
        echo "✅ Despliegue validado correctamente"
        exit 0
    fi
    
    echo "❌ Health check fallido. Reintentando en 5 segundos..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 5
done

echo ""
echo "🚨 FALLO CRÍTICO - No se pudo conectar después de $MAX_RETRIES intentos"

execute_rollback() {
    echo ""
    echo "📋 Historial de revisiones antes del rollback:"
    kubectl rollout history deployment/kubefoods-backend
    
    # Solo intentar rollback si hay revisiones anteriores
    REVISION_COUNT=$(kubectl rollout history deployment/kubefoods-backend 2>/dev/null | grep -c "revision" || echo "0")
    
    if [ "$REVISION_COUNT" -gt 1 ]; then
        echo "🔄 Ejecutando rollback automático..."
        kubectl rollout undo deployment/kubefoods-backend
        echo "✅ Rollback completado"
        
        echo ""
        echo "📊 Estado después del rollback:"
        kubectl rollout status deployment/kubefoods-backend --timeout=120s
        echo "🎯 Rollback ejecutado exitosamente"
    else
        echo "⚠️  No hay revisiones anteriores para hacer rollback"
        echo "🔧 Eliminando deployment fallido..."
        kubectl delete deployment kubefoods-backend --ignore-not-found=true
    fi
}

# Ejecutar rollback
execute_rollback

exit 1
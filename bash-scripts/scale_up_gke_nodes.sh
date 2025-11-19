#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-your-cluster}"
NODE_POOL_NAME="${NODE_POOL_NAME:-default-pool}"
ZONE="${ZONE:-us-central1-a}"
DESIRED_NODES="${DESIRED_NODES:-3}"
LOG_FILE="${LOG_FILE:-/tmp/scale_up_gke_nodes.log}"
NAMESPACE="${NAMESPACE:-default}"
REDIS_RELEASE_NAME="${REDIS_RELEASE_NAME:-redis}"
REDIS_CHART_PATH="${REDIS_CHART_PATH:-./charts/redis}"
ALERT_EMAIL="${ALERT_EMAIL:-ops@example.com}"

# Redirect both standard output and error to the log file
echo "Starting resize of node pool at $(date)" >> "$LOG_FILE" 2>&1

# Resize the node pool
gcloud container clusters resize "${CLUSTER_NAME}" \
    --node-pool "${NODE_POOL_NAME}" \
    --num-nodes "${DESIRED_NODES}" \
    --zone "${ZONE}" --quiet >> "${LOG_FILE}" 2>&1

# Log the end time of resizing
echo "Resize completed at $(date)" >> "$LOG_FILE" 2>&1
echo "GKE node pool scaled to ${DESIRED_NODES}" | mailx -s "GKE Scale-up Success" "${ALERT_EMAIL}"

# Wait for 10 minutes to ensure node pool scaling is stable
echo "Waiting for 10 minutes to ensure scaling stability..." >> "$LOG_FILE" 2>&1
sleep 600

export PATH=$PATH:/usr/local/bin

# Check for the existing Redis Helm release
echo "Checking existing Redis installation..." >> "$LOG_FILE" 2>&1
if helm ls -n "$NAMESPACE" | grep -q "$REDIS_RELEASE_NAME"; then
    echo "Found existing Redis release. Uninstalling..." >> "$LOG_FILE" 2>&1
    helm uninstall "$REDIS_RELEASE_NAME" -n "$NAMESPACE" >> "$LOG_FILE" 2>&1
    
    # Delete Redis PVCs
    echo "Deleting Redis PVCs..." >> "$LOG_FILE" 2>&1
    kubectl get pvc -n "$NAMESPACE" | grep "$REDIS_RELEASE_NAME" | awk '{print $1}' | xargs -r kubectl delete pvc -n "$NAMESPACE" >> "$LOG_FILE" 2>&1
else
    echo "No existing Redis release found." >> "$LOG_FILE" 2>&1
fi

# Reinstall Redis
echo "Installing Redis from chart located at $REDIS_CHART_PATH..." >> "$LOG_FILE" 2>&1
helm install "${REDIS_RELEASE_NAME}" "${REDIS_CHART_PATH}" -n "${NAMESPACE}" >> "$LOG_FILE" 2>&1

# Confirm installation
if helm ls -n "$NAMESPACE" | grep -q "$REDIS_RELEASE_NAME"; then
    echo "Redis reinstalled successfully at $(date)." >> "$LOG_FILE" 2>&1
else
    echo "Redis installation failed. Check the logs for details." >> "$LOG_FILE" 2>&1
fi

echo "Script completed at $(date)" >> "$LOG_FILE" 2>&1



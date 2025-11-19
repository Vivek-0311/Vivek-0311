#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-your-cluster}"
NODE_POOL_NAME="${NODE_POOL_NAME:-default-pool}"
ZONE="${ZONE:-us-central1-a}"
DESIRED_NODES="${DESIRED_NODES:-0}"
LOG_FILE="${LOG_FILE:-/tmp/resize_gke_nodes.log}"
ALERT_EMAIL="${ALERT_EMAIL:-ops@example.com}"

# Log start time
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting GKE node pool resize" >> $LOG_FILE

gcloud container clusters resize "${CLUSTER_NAME}" \
    --node-pool "${NODE_POOL_NAME}" \
    --num-nodes "${DESIRED_NODES}" \
    --zone "${ZONE}" --quiet >> "${LOG_FILE}" 2>&1

# Check if the resize operation was successful
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GKE node pool resized to ${DESIRED_NODES} nodes successfully" >> "${LOG_FILE}"
    echo "GKE node pool resized to ${DESIRED_NODES}" | mailx -s "GKE Resize Success" "${ALERT_EMAIL}"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - GKE node pool resize failed" >> "${LOG_FILE}"
    echo "GKE node pool resize failed" | mailx -s "GKE Resize Failed" "${ALERT_EMAIL}"
fi

# Log end time
echo "$(date '+%Y-%m-%d %H:%M:%S') - Finished GKE node pool resize" >> "${LOG_FILE}"


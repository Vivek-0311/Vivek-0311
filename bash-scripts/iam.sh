#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gcp-project-id}"
PROJECT_NUMBER="${PROJECT_NUMBER:-000000000000}"
NAMESPACE="${NAMESPACE:-default}"

# List of secrets and their corresponding Kubernetes Service Accounts (KSA)
declare -A SECRET_KSA_MAP=(
    ["secret-a"]="app-a-sa"
    ["secret-b"]="app-b-sa"
)

# Loop through each secret and add IAM policy binding
for SECRET_NAME in "${!SECRET_KSA_MAP[@]}"; do
    KSA_NAME="${SECRET_KSA_MAP[$SECRET_NAME]}"
    echo "Adding IAM policy binding to secret: $SECRET_NAME with KSA: $KSA_NAME"

    # Construct the IAM policy binding command
    gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
        --role="roles/secretmanager.secretAccessor" \
        --member="principal://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/$NAMESPACE/sa/$KSA_NAME" \
        --project="$PROJECT_ID" || { echo "Failed to add policy to $SECRET_NAME. Skipping..."; continue; }

    echo "IAM policy binding successfully added to $SECRET_NAME"
    echo "-----------------------------------------------"
done

echo "All secrets processed."

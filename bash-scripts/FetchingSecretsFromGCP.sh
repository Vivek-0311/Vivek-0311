#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gcp-project-id}"
OUTPUT_DIR="${OUTPUT_DIR:-./secrets}"
IFS=',' read -r -a SECRETS_TO_FETCH <<<"${SECRETS_TO_FETCH:-secret-a,secret-b}"

mkdir -p "${OUTPUT_DIR}"

for SECRET_NAME in "${SECRETS_TO_FETCH[@]}"; do
    [[ -z "${SECRET_NAME}" ]] && continue
    echo "Downloading value for secret: ${SECRET_NAME}"

    SECRET_VERSION=$(gcloud secrets versions list "${SECRET_NAME}" --project="${PROJECT_ID}" --format="value(name)" --limit=1)

    if [[ -z "${SECRET_VERSION}" ]]; then
        echo "No versions found for ${SECRET_NAME}. Skipping..."
        continue
    fi

    SECRET_VALUE=$(gcloud secrets versions access "${SECRET_VERSION}" --secret="${SECRET_NAME}" --project="${PROJECT_ID}")

    if [[ -z "${SECRET_VALUE}" ]]; then
        echo "Failed to download value for ${SECRET_NAME}"
        continue
    fi

    echo "${SECRET_VALUE}" > "${OUTPUT_DIR}/${SECRET_NAME}"
    echo "Secret '${SECRET_NAME}' saved to ${OUTPUT_DIR}/${SECRET_NAME}"
    echo "-----------------------------------------------"
done

echo "All specified secrets have been downloaded."


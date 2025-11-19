#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gcp-project-id}"
OUTPUT_DIR="${OUTPUT_DIR:-./secrets}"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# List all secrets in the project
SECRET_NAMES=$(gcloud secrets list --project="$PROJECT_ID" --format="value(name)")

# Loop through each secret and download its value
for SECRET_NAME in $SECRET_NAMES; do
    echo "Downloading value for secret: $SECRET_NAME"

    # Get the latest version of the secret
    SECRET_VERSION=$(gcloud secrets versions list "$SECRET_NAME" --project="$PROJECT_ID" --format="value(name)" --limit=1)

    if [ -z "$SECRET_VERSION" ]; then
        echo "No versions found for secret: $SECRET_NAME. Skipping..."
        continue
    fi

    # Download the secret value using the latest version and save to a local file
    SECRET_VALUE=$(gcloud secrets versions access "$SECRET_VERSION" --secret="$SECRET_NAME" --project="$PROJECT_ID")

    if [ -z "$SECRET_VALUE" ]; then
        echo "Failed to download value for secret: $SECRET_NAME"
        continue
    fi

    # Save the secret value to a local file with the name of the secret
    echo "$SECRET_VALUE" > "$OUTPUT_DIR/$SECRET_NAME"

    echo "Secret '$SECRET_NAME' saved to $OUTPUT_DIR/$SECRET_NAME"
    echo "-----------------------------------------------"
done

echo "All secrets have been downloaded."

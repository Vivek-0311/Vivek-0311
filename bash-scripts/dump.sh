#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gcp-project-id}"
gcloud config set project "${PROJECT_ID}" >/dev/null

# Get the folder path where secrets are stored
SECRET_FOLDER="$1"

# Check if the folder path is provided
if [ -z "$SECRET_FOLDER" ]; then
  echo "Please provide the path to the folder containing secrets."
  exit 1
fi

# Check if the folder exists
if [ ! -d "$SECRET_FOLDER" ]; then
  echo "The folder '$SECRET_FOLDER' does not exist."
  exit 1
fi

# Loop over all files in the specified folder
for SECRET_FILE in "$SECRET_FOLDER"/*; do
  # Check if it's a file (ignore directories)
  if [ -f "$SECRET_FILE" ]; then
    # Get the secret name from the filename (without extension)
    SECRET_NAME=$(basename "$SECRET_FILE" | cut -d. -f1)

    # Check if the secret already exists
    if gcloud secrets describe "${SECRET_NAME}" --project="${PROJECT_ID}" &> /dev/null; then
      echo "Secret '$SECRET_NAME' already exists. Creating a new version..."
    else
      # If the secret doesn't exist, create it
      echo "Secret '$SECRET_NAME' doesn't exist. Creating a new secret..."
        gcloud secrets create "${SECRET_NAME}" --replication-policy="automatic" --project="${PROJECT_ID}"
    fi

    # Read the secret content from the file
    SECRET_CONTENT=$(<"$SECRET_FILE")

    echo -n "$SECRET_CONTENT" | gcloud secrets versions add "${SECRET_NAME}" --data-file=- --project="${PROJECT_ID}"

    # Confirm success
    echo "Secret '$SECRET_NAME' has been successfully pushed to GCP Secret Manager!"
  fi
done

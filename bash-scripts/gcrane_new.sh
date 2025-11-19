#!/usr/bin/env bash

set -euo pipefail

SRC_REPO="${SRC_REPO:-gcr.io/source-project/repository}"
DEST_REPO="${DEST_REPO:-gcr.io/destination-project/repository}"
IMAGE_FILE="${IMAGE_FILE:-images.txt}"

# Check if file exists
if [ ! -f "$IMAGE_FILE" ]; then
  echo "❌ Error: $IMAGE_FILE not found!"
  exit 1
fi

# Loop through images and copy
while IFS= read -r IMAGE || [ -n "$IMAGE" ]; do
  # Skip empty lines and comments
  [[ -z "$IMAGE" || "$IMAGE" =~ ^# ]] && continue
  
  echo "🚀 Copying ${IMAGE}..."
  gcrane cp "${SRC_REPO%/}/${IMAGE}" "${DEST_REPO%/}/${IMAGE}"
  
  if [ $? -eq 0 ]; then
    echo "✅ Successfully copied $IMAGE"
  else
    echo "❌ Failed to copy $IMAGE"
  fi
done < "$IMAGE_FILE"


#!/usr/bin/env bash

set -euo pipefail

SRC_REPO="${SRC_REPO:-gcr.io/source-project/repository}"
DEST_REPO="${DEST_REPO:-gcr.io/destination-project/repository}"

IMAGES=("${IMAGES[@]:-}")
if [[ ${#IMAGES[@]} -eq 0 ]]; then
  IMAGES=("service-x:v1.0.0")
fi

IMAGES=($(printf "%s\n" "${IMAGES[@]}" | sed '/^$/d' | sort -u))

for IMAGE in "${IMAGES[@]}"; do
  echo "🚀 Copying ${IMAGE}..."
  if gcrane cp "${SRC_REPO%/}/${IMAGE}" "${DEST_REPO%/}/${IMAGE}"; then
    echo "✅ Successfully copied ${IMAGE}"
  else
    echo "❌ Failed to copy ${IMAGE}"
  fi
done


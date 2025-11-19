#!/usr/bin/env bash

set -euo pipefail

SRC_REPO="${SRC_REPO:-gcr.io/source-project/repository}"
DEST_REPO="${DEST_REPO:-gcr.io/destination-project/repository}"

# Provide image:tag pairs via IMAGES array or comma-separated env var
if [[ -n "${IMAGES_CSV:-}" ]]; then
  IFS=',' read -r -a IMAGES <<<"${IMAGES_CSV}"
elif [[ ${#IMAGES[@]} -eq 0 ]]; then
  IMAGES=(
    "service-a:1.0.0"
    "service-b:2.3.4"
  )
fi

for IMAGE in "${IMAGES[@]}"; do
  [[ -z "${IMAGE}" ]] && continue
  echo "Copying ${IMAGE}..."
  if gcrane cp "${SRC_REPO%/}/${IMAGE}" "${DEST_REPO%/}/${IMAGE}"; then
    echo "Successfully copied ${IMAGE}"
  else
    echo "Failed to copy ${IMAGE}"
  fi
done


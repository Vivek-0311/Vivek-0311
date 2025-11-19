#!/usr/bin/env bash

set -euo pipefail

IMAGE_LIST="${IMAGE_LIST:-images.txt}"
TARGET_REGISTRY="${TARGET_REGISTRY:-${NEW_REGISTRY:-}}"

if [[ -z "${TARGET_REGISTRY}" ]]; then
  echo "Set TARGET_REGISTRY (e.g. gcr.io/my-project/repo) before running." >&2
  exit 1
fi

if [[ ! -f "${IMAGE_LIST}" ]]; then
  echo "Image list not found: ${IMAGE_LIST}" >&2
  exit 1
fi

while IFS= read -r IMAGE || [[ -n "${IMAGE}" ]]; do
  [[ -z "${IMAGE}" || "${IMAGE}" =~ ^# ]] && continue

  echo "Pulling ${IMAGE}"
  docker pull "${IMAGE}"

  IMAGE_NAME=$(echo "${IMAGE}" | awk -F'/' '{print $NF}')
  NEW_IMAGE="${TARGET_REGISTRY%/}/${IMAGE_NAME}"

  echo "Tagging ${IMAGE} as ${NEW_IMAGE}"
  docker tag "${IMAGE}" "${NEW_IMAGE}"

  echo "Pushing ${NEW_IMAGE}"
  docker push "${NEW_IMAGE}"
done < "${IMAGE_LIST}"

echo "All images processed."
#!/usr/bin/env bash

set -euo pipefail

SRC_REPO="${SRC_REPO:-gcr.io/source-project/repository}"
DEST_REPO="${DEST_REPO:-gcr.io/destination-project/repository}"
TAG="${TAG:-latest}"

gcrane cp "${SRC_REPO%/}:${TAG}" "${DEST_REPO%/}:${TAG}"


#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./ci-build.sh -i repo/image -t tag [-p registry] [--sbom]

Builds and pushes a Docker image with optional SBOM generation via syft.
Environment variables:
  REGISTRY (optional) - default registry (e.g. gcr.io/my-project)
  DOCKERFILE - alternative Dockerfile path (default: ./Dockerfile)

Examples:
  ./ci-build.sh -i demo/api -t $(git rev-parse --short HEAD)
  ./ci-build.sh -i demo/api -t latest -p us-central1-docker.pkg.dev/proj/repo --sbom
EOF
}

image=""
tag=""
registry="${REGISTRY:-}"
sbom=false
dockerfile="${DOCKERFILE:-Dockerfile}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--image) image="$2"; shift 2 ;;
    -t|--tag) tag="$2"; shift 2 ;;
    -p|--registry) registry="$2"; shift 2 ;;
    --sbom) sbom=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${image}" || -z "${tag}" ]]; then
  echo "Image and tag are required." >&2
  usage
  exit 1
fi

if [[ ! -f "${dockerfile}" ]]; then
  echo "Dockerfile not found at ${dockerfile}" >&2
  exit 1
fi

full_image="${image}:${tag}"
if [[ -n "${registry}" ]]; then
  full_image="${registry%/}/${image}:${tag}"
fi

echo "Building ${full_image} using ${dockerfile}"
docker build -f "${dockerfile}" -t "${full_image}" .

echo "Pushing ${full_image}"
docker push "${full_image}"

if [[ "${sbom}" == true ]]; then
  if ! command -v syft >/dev/null 2>&1; then
    echo "syft not installed; skipping SBOM" >&2
  else
    sbom_file="sbom-$(echo "${image}" | tr '/:' '__')-${tag}.json"
    echo "Generating SBOM -> ${sbom_file}"
    syft "${full_image}" -o json > "${sbom_file}"
  fi
fi

echo "Done."


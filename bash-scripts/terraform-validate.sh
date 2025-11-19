#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./terraform-validate.sh [directory]

Runs `terraform fmt`, `init`, `validate`, and optional `tflint`
across Terraform modules/workspaces. Defaults to current directory.

Environment variables:
  TF_BACKEND_BUCKET  - remote state bucket for init (optional)
  TF_BACKEND_PREFIX  - remote state prefix (optional)
  TFLINT             - set to "false" to skip tflint (default: auto-run if installed)

Examples:
  ./terraform-validate.sh infra/envs/prod
  TFLINT=false ./terraform-validate.sh modules/network
EOF
}

target_dir="${1:-.}"

if [[ "${target_dir}" == "-h" || "${target_dir}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "${target_dir}" ]]; then
  echo "Directory not found: ${target_dir}" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform CLI is required" >&2
  exit 1
fi

pushd "${target_dir}" >/dev/null

echo "Formatting Terraform files..."
terraform fmt -recursive

init_args=("-input=false")
if [[ -n "${TF_BACKEND_BUCKET:-}" ]]; then
  init_args+=(-backend-config="bucket=${TF_BACKEND_BUCKET}")
fi
if [[ -n "${TF_BACKEND_PREFIX:-}" ]]; then
  init_args+=(-backend-config="prefix=${TF_BACKEND_PREFIX}")
fi

echo "Initializing backend..."
terraform init "${init_args[@]}"

echo "Validating configuration..."
terraform validate

if [[ "${TFLINT:-auto}" != "false" ]] && command -v tflint >/dev/null 2>&1; then
  echo "Running tflint..."
  tflint
else
  echo "Skipping tflint (not installed or disabled)"
fi

popd >/dev/null

echo "Terraform checks complete."


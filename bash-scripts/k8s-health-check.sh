#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./k8s-health-check.sh [-c context] [-n namespace1,namespace2,...]

Runs quick-readiness checks across pods, cronjobs, and nodes.
Defaults to all namespaces and the current kubectl context.

Examples:
  ./k8s-health-check.sh
  ./k8s-health-check.sh -c prod-gke -n kube-system,platform
EOF
}

COLOR_OK=$(tput setaf 2 || true)
COLOR_WARN=$(tput setaf 3 || true)
COLOR_ERR=$(tput setaf 1 || true)
COLOR_RESET=$(tput sgr0 || true)

context=""
namespaces=""

while getopts ":c:n:h" opt; do
  case "${opt}" in
    c) context="${OPTARG}" ;;
    n) namespaces="${OPTARG}" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH" >&2
  exit 1
fi

kubectl_ctx_args=()
if [[ -n "${context}" ]]; then
  kubectl_ctx_args+=(--context "${context}")
fi

if [[ -z "${namespaces}" ]]; then
  mapfile -t ns_list < <(kubectl "${kubectl_ctx_args[@]}" get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
else
  IFS=',' read -ra ns_list <<<"${namespaces}"
fi

echo "Checking context: ${context:-$(kubectl config current-context)}"
echo "Namespaces: ${ns_list[*]}"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "----------------------------------------"

for ns in "${ns_list[@]}"; do
  echo "Namespace: ${ns}"

  if ! kubectl "${kubectl_ctx_args[@]}" get ns "${ns}" >/dev/null 2>&1; then
    echo "  ${COLOR_ERR}✖ Missing namespace${COLOR_RESET}"
    continue
  fi

  echo "  Pods:"
  kubectl "${kubectl_ctx_args[@]}" get pods -n "${ns}" --no-headers \
    | awk -v ok="${COLOR_OK}" -v warn="${COLOR_WARN}" -v err="${COLOR_ERR}" -v reset="${COLOR_RESET}" '
        {
          status=$3
          if (status ~ /Running|Completed/) {
            printf "    %s✔ %s (%s/%s)%s\n", ok, $1, $2, status, reset
          } else if (status ~ /Pending|ContainerCreating/) {
            printf "    %s● %s (%s)%s\n", warn, $1, status, reset
          } else {
            printf "    %s✖ %s (%s)%s\n", err, $1, status, reset
          }
        }
      '

  echo "  CronJobs:"
  kubectl "${kubectl_ctx_args[@]}" get cronjobs.batch -n "${ns}" --no-headers 2>/dev/null \
    | awk '{printf "    • %s (schedule: %s, suspend: %s)\n", $1, $2, $3}' || echo "    none"

  echo
done

echo "Nodes summary:"
kubectl "${kubectl_ctx_args[@]}" get nodes -o wide


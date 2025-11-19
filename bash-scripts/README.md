# Bash Automation Toolkit

Portable scripts for day-to-day DevOps tasks. Every helper is:

- **Idempotent** – re-runs safely
- **Configurable** – driven by env vars / flags
- **CI ready** – exits on failure, streams logs

Run `chmod +x *.sh` before executing anything locally or in CI.

---

## Script Map

| Script | What it solves | Inputs to set |
| --- | --- | --- |
| `k8s-health-check.sh` | Quick view of pod/cronjob/node health per namespace. | `-c` context, `-n` namespaces |
| `ci-build.sh` | Docker build + push with optional Syft SBOM artifact. | `REGISTRY`, `DOCKERFILE`, `--sbom` |
| `terraform-validate.sh` | `fmt → init → validate (+tflint)` wrapper for modules/envs. | `TF_BACKEND_BUCKET`, `TF_BACKEND_PREFIX`, `TFLINT` |
| `pullpush.sh` / `pull.sh` | Re-tag images from `images.txt` into a destination registry. | `TARGET_REGISTRY`, `IMAGE_LIST` |
| `gcrane_*.sh` / `gimage.sh` | Copy images between OCI registries using `gcrane cp`. | `SRC_REPO`, `DEST_REPO`, `IMAGES` |
| `scale_up_gke_nodes.sh` / `resize_gke_nodes.sh` | Resize GKE node pools and trigger follow-up tasks. | `CLUSTER_NAME`, `NODE_POOL_NAME`, `ZONE`, `DESIRED_NODES` |
| `FetchingSecretsFromGCP.sh` / `secret.sh` / `dump.sh` / `iam.sh` | Fetch, push, or grant access to Secret Manager entries. | `PROJECT_ID`, `SECRETS_TO_FETCH`, `OUTPUT_DIR`, etc. |
| `backend_nawat_pipeline.sh` | Sample Jenkins pipeline for Maven build → image → deploy. | Update params + inline envs |
| `MySQLBackup/dumpScript.sh` | Opinionated MySQL dump/compress/upload workflow. | `ACCESS_KEY`, `SECRET_KEY`, `CLUSTERS`, `MINIO_BUCKET` |

Use this table as a checklist when wiring scripts into GitHub Actions, Jenkins, or manual ops.

---

## How To Use

1. **Clone/Download** this repo or copy the scripts you need.
2. **Install prerequisites** such as `kubectl`, `gcloud`, `docker`, `terraform`, `tflint`, `syft`, `gcrane`, `mc`, `mysql`.
3. **Export required variables**. Example: `export TARGET_REGISTRY=gcr.io/demo/artifacts`.
4. **Dry-run locally** before adding to CI: `./bash-scripts/k8s-health-check.sh -n default`.
5. **Document your defaults** in a `.env.example` (not committed) so teammates can follow.

---

## Extending The Toolkit

- Copy an existing script when adding a new helper and keep `set -euo pipefail`.
- Add usage docs at the top (`usage()` or comment block) plus guardrails for missing inputs.
- Update this README’s table whenever a new script lands or behavior changes.
- Prefer neutral placeholders (`your-project`, `service-a`) so the toolkit stays client-agnostic.

Questions or ideas? Drop a note in issues or PRs—always happy to make automation cleaner. 🚀


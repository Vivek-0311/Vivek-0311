# Bash Automation Toolkit

Utility scripts I lean on for day-to-day DevOps work. Each script is designed to be:

- **Idempotent** – safe to rerun
- **Env-var driven** – no hard-coded secrets
- **CI friendly** – pipes logs, exits on failure

> Run `chmod +x *.sh` before using any script.

---

## Quick Index

| Script | Description | Key Env Vars / Flags |
| --- | --- | --- |
| `k8s-health-check.sh` | Prints pod/cronjob/node status across namespaces with color-coded output. | `-c` kubectl context, `-n` namespace list |
| `ci-build.sh` | Builds and pushes Docker images with optional Syft SBOM. | `REGISTRY`, `DOCKERFILE`, `--sbom` |
| `terraform-validate.sh` | Runs `fmt → init → validate (+tflint)` for Terraform modules. | `TF_BACKEND_BUCKET`, `TF_BACKEND_PREFIX`, `TFLINT` |
| `pullpush.sh` | Re-tags images listed in `images.txt` and pushes to a new registry. | `NEW_REGISTRY` inside script |
| `scale_up_gke_nodes.sh` / `resize_gke_nodes.sh` | Adjusts GKE node-pool size via `gcloud`. | `PROJECT_ID`, `CLUSTER`, `ZONE`, `POOL`, `SIZE` |
| `FetchingSecretsFromGCP.sh` / `secret.sh` | Fetches secrets from Secret Manager for local or CI use. | `PROJECT_ID`, `SECRET_ID`, `VERSION` |
| `backend_nawat_pipeline.sh` | Example end-to-end CI/CD pipeline orchestration for backend services. | See inline comments for stages |
| `MySQLBackup/dumpScript.sh` | Parameterized MySQL dump with Docker and optional uploads. | `DB_HOST`, `DB_USER`, `DB_NAME`, `OUTPUT_DIR` |

---

## Getting Started

1. **Clone Tools** – `git clone git@github.com:Vivek-0311/REPO.git`
2. **Install CLIs** – `kubectl`, `gcloud`, `docker`, `terraform`, `syft`, `tflint`
3. **Export Env Vars** – create a `.env` or use your CI secrets manager
4. **Run Scripts** – `./bash-scripts/<script>.sh --help` when available

---

## Tips

- Pair scripts with GitHub Actions or Jenkins to keep pipelines DRY.
- Add `set -euo pipefail` to new scripts for safer error handling.
- Document new utilities here so recruiters and teammates understand your toolkit.

Happy automating! 🚀


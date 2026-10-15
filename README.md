# Simple GKE GitOps Store — Phase 1 (no Istio, no Cloud SQL)

This starter contains React frontend, Product API, Order API, PostgreSQL in GKE, Helm/Argo CD manifests, Terraform modules, GitHub Actions tests/quality/image publishing, SonarQube Cloud integration, and k6 performance smoke tests.

## Architecture

Browser → GKE external LoadBalancer Service → NGINX static frontend/reverse proxy → Product API and Order API ClusterIP Services → PostgreSQL StatefulSet/PVC. No Istio and no Cloud SQL in this phase. The frontend NGINX routes `/api/products` to `product-api:8000` and `/api/orders` to `order-api:8000`.

> Lab caveat: PostgreSQL in a single StatefulSet is for learning only, not highly available or production-grade. The example creates tables at API startup; use Alembic migrations and managed database HA for production.

## Critical: existing cluster and Terraform safety

Your existing cluster is `gke-istio-lab` in `us-central1-a`, project `k8s-learning-510807`. Do **not** run `terraform apply` directly against it. The current VPC/subnet, IP ranges, node-pool name/configuration, release channel, Workload Identity, and add-ons must be inventoried first. Changing the VPC of an existing GKE cluster is not an in-place migration and can require replacement/recreation.

This starter deliberately defaults to `manage_gke_cluster = false` and `create_network = false` so a first apply does not create a second cluster or a new VPC. The GKE module is a target configuration template, not guaranteed to match the already-running cluster. Before managing the cluster:

1. Capture current settings:

```bash
gcloud config set project k8s-learning-510807
gcloud container clusters describe gke-istio-lab --zone us-central1-a --format=yaml > current-cluster.yaml
gcloud container node-pools list --cluster gke-istio-lab --zone us-central1-a
gcloud compute networks subnets list --regions us-central1
gcloud container node-pools describe NODE_POOL_NAME --cluster gke-istio-lab --zone us-central1-a --format=yaml > current-node-pool.yaml
```

2. Inspect current project/network and node pool details. Keep a backup of the YAML output.
3. Configure the matching existing network and subnet names/CIDRs. Do not enable `create_network` unless you intentionally plan a migration/new cluster.
4. Configure a protected GCS Terraform backend and restrict access to the state bucket.
5. After editing the module variables/resources to match the captured settings, set `manage_gke_cluster = true` in your local `terraform.tfvars` so the import addresses exist. Import the existing cluster and exact node pool. Example (verify IDs and node-pool name first):

```bash
terraform import 'module.gke[0].google_container_cluster.this' 'projects/k8s-learning-510807/locations/us-central1-a/clusters/gke-istio-lab'
terraform import 'module.gke[0].google_container_node_pool.primary' 'projects/k8s-learning-510807/locations/us-central1-a/clusters/gke-istio-lab/nodePools/EXACT_NODE_POOL_NAME'
```

6. Run `terraform plan` and review every change. Do not apply if the plan says it will replace/destroy the cluster, node pool, network, subnet, or disk. The module's `prevent_destroy` is a safety net, not a substitute for reviewing the plan.

The current GKE configuration was not fetched during generation; no claim is made that the sample module will produce a no-op plan for your live cluster.

## Terraform structure

```text
terraform/
  environments/dev/
    versions.tf variables.tf outputs.tf terraform.tfvars.example
    gke.tf network.tf billing.tf artifact-registry.tf secrets.tf iam.tf
  modules/
    gke/                 # cluster + node pool template (guarded)
    vpc/                 # custom VPC and custom subnet/secondary ranges
    artifact-registry/   # Docker repository
    secret-manager/      # secret containers; values are provisioned separately
    iam/                 # GitHub WIF, CI service account, workload service account, IAM
```

Terraform creates Secret Manager **secret resources**, not secret values. Add values separately so real tokens/passwords are not committed or embedded in `.tf` files. State may still contain sensitive metadata and must be protected.

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

The starter is scaffolded to manage cloud resources. Existing Artifact Registry, service accounts, WIF pools/providers, secrets, VPC, and subnet resources may need importing if they already exist. For example, import an existing Artifact Registry repository with `terraform import 'module.artifact_registry.google_artifact_registry_repository.docker' projects/k8s-learning-510807/locations/us-central1/repositories/microservices`; inspect provider import formats for other resources before importing them. Resolve `already exists` errors by importing the correct resource—not by deleting live resources.

### Billing

`billing.tf` defaults to not managing project billing. If you explicitly want Terraform to manage billing for the existing project, first verify your billing account and import the project into the configured resource address before enabling `manage_project_billing`. Never use Terraform to detach billing as an experiment.

## Secret Manager

The Terraform module creates `sonar-token` and `store-postgres-password`. Add secret versions separately:

```bash
read -rsp 'Sonar token: ' TOKEN; echo
printf '%s' "$TOKEN" | gcloud secrets versions add sonar-token --data-file=-
unset TOKEN

read -rsp 'Database password: ' TOKEN; echo
printf '%s' "$TOKEN" | gcloud secrets versions add store-postgres-password --data-file=-
unset TOKEN
```

The CI workflow reads `sonar-token` using WIF. The workload service account is granted access to the database secret, but a secret permission alone does not inject a secret into a pod. For the runtime path, install/configure the GKE Secret Manager CSI driver or External Secrets Operator and map `store-postgres-password` to the Kubernetes Secret named `store-postgres-auth` expected by the Helm chart. Until that integration is configured, create `store-postgres-auth` securely in the `microservices` namespace. Do not commit its value. This separation is intentional; don't assume the Terraform IAM grant itself mounts the secret.

## GitHub repository settings

Create repository **variables**:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`: full provider resource name output by Terraform
- `GCP_GITHUB_ACTIONS_SERVICE_ACCOUNT`: CI service account email output by Terraform
- `SONAR_PROJECT_KEY`: SonarQube Cloud project key
- `SONAR_ORGANIZATION`: SonarQube Cloud organization key

The workflow retrieves `sonar-token` from Secret Manager. It does not require a GitHub secret for that token. WIF trust is scoped to `rxk41/GitOps`; adjust `github_repository` if you fork this repository. For pull requests from forks, cloud-authenticated Sonar analysis is skipped because fork PRs should not receive cloud credentials.

## CI stages

- Product and Order API: Ruff lint + pytest unit tests.
- Frontend: npm lint + Vitest tests + production build.
- SonarQube Cloud analysis after tests.
- On push to `main` or a `v*` Git tag, build/push three Docker images directly using `docker build`/`docker push` (no Docker Compose in CI).
- Main branch images use commit SHA tags; version tags such as `v1.0.0` use the Git tag as the image tag.

Image publishing is not deployment. Update `helm/store/values.yaml` to the selected image tags in a separate GitOps commit/PR; Argo CD syncs from Git. This starter does not auto-edit Helm values or directly deploy to the cluster.

## Local development

Requires Docker Compose:

```bash
docker compose up --build
```

Open `http://localhost:8080`. Product API docs: `http://localhost:8001/docs`; Order API docs: `http://localhost:8002/docs`. The Compose DB password is for local development only.

## Helm / Argo CD

Ensure the namespace exists and a Kubernetes Secret `store-postgres-auth` exists with key `password` before deploying. Set exact image tags in `helm/store/values.yaml`. Then:

```bash
helm lint helm/store
helm template store helm/store --namespace microservices
kubectl create namespace microservices --dry-run=client -o yaml | kubectl apply -f -
kubectl -n microservices create secret generic store-postgres-auth --from-literal=password='REPLACE_SECURELY' --dry-run=client -o yaml | kubectl apply -f -
```

Use an approved secret injection process rather than putting a real password in shell history. In a shared cluster, install/configure the Secret Manager CSI or External Secrets integration first. Argo CD Application is at `k8s-platform/argocd/applications/store.yaml`.

The frontend Service type is `LoadBalancer`; after sync, get its external IP with `kubectl -n microservices get svc frontend`. This exposes the frontend publicly. Restrict access or use an internal LB if needed.

## PDB, affinity, taints, and resource requests

- API and frontend pods have CPU/memory requests and limits.
- A frontend PodDisruptionBudget has `minAvailable: 1`.
- Soft pod anti-affinity encourages replicas onto different nodes but does not make it mandatory (important for a small 2-node lab).
- `nodeSelector` and `tolerations` are configurable in `values.yaml`; leave empty unless you have matching node labels/taints. Don't add taints without adding matching tolerations or workloads may stay Pending.
- PostgreSQL intentionally remains a single replica and is not covered by a PDB because it cannot provide HA.

## Performance testing with k6

Install k6, then after deployment:

```bash
k6 run -e BASE_URL=http://EXTERNAL_FRONTEND_IP performance/k6-smoke.js
```

Default test: 10 VUs for 2 minutes, checks health/product/order GET endpoints, p95 under 500 ms and failure rate under 1%. Tune thresholds based on a measured baseline; run load tests carefully to control cloud costs.

## Phase 2

Add Istio separately after Phase 1 is stable: install Istio, enable namespace injection, create Gateway/VirtualService/DestinationRules, then remove the frontend's API reverse-proxy rules if Istio will route API paths at the ingress layer. Avoid running both routing layers unintentionally.

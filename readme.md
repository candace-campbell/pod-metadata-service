# Pod metadata display

A small Go web server that returns the metadata of the pod serving the request (container hostname, namespace, pod IP, node name). This was built to demonstrate
an end-to-end path from source code to a running workload on Amazon EKS, including
the container build, IaC, and CI/CD.

## What this project demonstrates

- **Go application** with a minimal HTTP API and liveness endpoint.
- **Containerization** with a multi-stage `Dockerfile` producing a minimal image.
- **Kubernetes** Service and Deployment manifests exposing three replicas.
- **Infrastructure as code** with Terraform provisioning a VPC and an EKS cluster.
- **CI/CD** with GitHub Actions using OIDC to assume an AWS role (no long-lived keys),
  running validation on pull requests and building/pushing images to ECR on merge.


## Repo layout

| Path | Description |
| --- | --- |
| `app/` | Go source, module definition, and tests |
| `Dockerfile` | Multi-stage build producing a minimal runtime image |
| `k8s/` | Kubernetes Deployment and Service manifests |
| `terraform/` | VPC and EKS infrastructure, split into reusable modules |
| `.github/workflows/` | CI (`ci.yml`) and image build/push (`deploy.yaml`) pipelines. |

## Application

The service exposes two endpoints:

| Endpoint | Description |
| --- | --- |
| `GET /` | Returns pod metadata as JSON. |
| `GET /healthz` | Liveness probe endpoint; returns `ok`. |

Metadata is read from environment variables that the Deployment populates from
the Kubernetes downward API (`HOSTNAME`, `POD_NAMESPACE`, `POD_IP`, `NODE_NAME`).
When run outside a cluster, it falls back to default values. The listen
port can be overridden with the `PORT` environment variable (default `8081`).

### Run locally

```bash
cd app
go run .
# in another shell
curl localhost:8081/
```

*Note:* Outside a cluster the endpoint returns default values unless you set the
metadata environment variables yourself (e.g. `export HOSTNAME=my-host`).

### Run tests

```bash
cd app
go test -v
```

## How to deploy

### Infrastructure

The `terraform/` directory provisions the VPC and the EKS cluster, along with the
managed node group and cluster add-ons. The Terraform state is stored in an S3 backend, so the
bucket referenced in `terraform/provider.tf` must already exist before you run
`terraform init`.

```bash
cd terraform

# Download providers and configure the S3 backend
terraform init

# Review the planned changes
terraform plan

# Provision the VPC and EKS cluster
terraform apply
```

### EKS

After creating cluster, run the following to grant EKS access via Access Entries.
Replace `<AWS_ACCOUNT_ID>` with your account ID and the principal ARNs with the
group/user you want to grant access to.

1. Update cluster auth mode if necessary

```bash
aws eks update-cluster-config \
  --name pod-metadata-cluster \
  --access-config authenticationMode=API_AND_CONFIG_MAP
```

2. Grant access

```bash
aws eks create-access-entry \
  --cluster-name pod-metadata-cluster \
  --principal-arn arn:aws:iam::<AWS_ACCOUNT_ID>:group/<GROUP_NAME>

aws eks associate-access-policy \
  --cluster-name pod-metadata-cluster \
  --principal-arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/<USERNAME> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

```

### Deploy the application

Once the cluster is up and access has been granted, add it to your kubeconfig so
`kubectl` targets the new cluster, then apply the manifests in `k8s/`.

```bash
# Update your local kubeconfig to target the cluster
aws eks update-kubeconfig --name pod-metadata-cluster --region us-east-1

# Apply the Deployment and Service
kubectl apply -f k8s/deployment.yml -f k8s/service.yml
```

Verify the deployment and find the load balancer's external address:

```bash
kubectl get pods -l app=pod-metadata
kubectl get service pod-metadata-service
```

Once this verification is successful you can hit the load balancer's endpoint to see the pod metadata:

```bash
curl http://<EXTERNAL-IP>/
```

# IaC for AI Workloads

> Infrastructure as Code for GPU-accelerated AI/ML workloads on AWS, GCP, and Azure. Terraform modules for GPU clusters, networking, storage, and IAM — with built-in cost controls and security baselines.

[![Terraform CI](https://github.com/cala21/iac-ai-workloads/actions/workflows/terraform.yml/badge.svg)](https://github.com/cala21/iac-ai-workloads/actions/workflows/terraform.yml)
[![Terraform 1.6+](https://img.shields.io/badge/Terraform-1.6+-purple)](https://terraform.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Modules

| Module | Description | Providers |
|--------|-------------|-----------|
| `gpu-cluster` | Auto Scaling Group with GPU instances, IMDSv2, encrypted EBS | AWS |
| `networking` | VPC, private subnets, NAT gateway, security groups | AWS / GCP |
| `storage` | S3/GCS buckets for model artifacts and training data | AWS / GCP |
| `iam` | Least-privilege roles for training, inference, and CI/CD | AWS |

## Quick Start

```bash
# 1. Clone
git clone https://github.com/cala21/iac-ai-workloads
cd iac-ai-workloads

# 2. Configure (copy example vars)
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
# Edit terraform.tfvars with your VPC/subnet IDs

# 3. Deploy dev environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## Repository Structure

```
├── terraform/
│   ├── modules/
│   │   ├── gpu-cluster/        # ASG + Launch Template for GPU instances
│   │   ├── networking/         # VPC and subnet config
│   │   ├── storage/            # Artifact and dataset buckets
│   │   └── iam/                # IAM roles and policies
│   └── environments/
│       ├── dev/                # Scale-to-zero, cost-optimized
│       ├── staging/            # Pre-prod validation
│       └── prod/               # HA, multi-AZ, stricter controls
├── pulumi/                     # Pulumi equivalents (Python SDK)
├── scripts/
│   └── estimate-costs.py       # GPU instance cost estimator
└── .github/
    └── workflows/
        └── terraform.yml       # Format check → plan → apply
```

## GPU Instance Reference (AWS eu-west-1)

Run `python scripts/estimate-costs.py` for current estimates. Rough guide:

| Instance | GPU | On-Demand /mo* | Spot /mo* | Best For |
|----------|-----|----------------|-----------|----------|
| `g4dn.xlarge` | T4 (16GB) | ~$650 | ~$195 | Inference, fine-tuning small models |
| `g4dn.12xlarge` | 4x T4 | ~$3,970 | ~$1,190 | Batch inference, parallel training |
| `p3.2xlarge` | V100 (16GB) | ~$3,380 | ~$1,015 | Training mid-size models |
| `p4d.24xlarge` | 8x A100 (320GB) | ~$28,960 | ~$8,690 | LLM training/fine-tuning |

*8 hours/day, 22 days/month. Spot savings ~70%.

**Cost tip:** Use `minReplicas: 0` in dev to scale to zero. g4dn.xlarge at 8h/day costs ~€20/day — shut it down nights and weekends.

## Security Baselines

All modules enforce:
- **IMDSv2** required on all EC2 instances (prevents SSRF → credential theft)
- **EBS encryption** at rest on all volumes
- **Least-privilege IAM** — separate roles for training, inference, and CI/CD
- **VPC isolation** — GPU nodes in private subnets, no public IPs

## CI/CD Pipeline

```
PR opened → terraform fmt check + validate → terraform plan (posted as PR comment)
Merge to main → terraform apply (dev environment)
Manual approval → terraform apply (staging/prod)
```

## Adapting for GCP / Azure

GCP and Azure provider configs are in `terraform/modules/*/providers_gcp.tf` and `providers_azure.tf`. Switch by changing the provider block in your environment's `main.tf`.

## License

MIT

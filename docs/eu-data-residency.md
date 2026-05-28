# EU Data Residency for AI Workloads

## Why This Matters

**EU AI Act Art. 10** requires high-risk AI systems to use data that meets quality criteria,
including appropriate data governance. **GDPR Art. 44-49** restricts transfers of personal data
outside the EU/EEA. For AI systems trained or running on personal data, both apply.

## Recommended EU Regions

### AWS
| Region | Location | Notes |
|--------|----------|-------|
| `eu-west-1` | Ireland | Largest EU region, most services available |
| `eu-central-1` | Frankfurt | German data sovereignty preference |
| `eu-south-1` | Milan | **Lowest latency for Italian deployments** |
| `eu-west-3` | Paris | French data sovereignty preference |

### GCP
| Region | Location | Notes |
|--------|----------|-------|
| `europe-west1` | Belgium | Default in this repo — broad service availability |
| `europe-west8` | Milan | **Best for Italian PMI — lowest latency** |
| `europe-west3` | Frankfurt | German preference |
| `europe-west9` | Paris | French preference |

### Azure
| Region | Location | Notes |
|--------|----------|-------|
| `Italy North` | Milan | Available since 2023, growing |
| `West Europe` | Netherlands | Largest EU Azure region |
| `Germany West Central` | Frankfurt | German data sovereignty |

## Enforcing EU-Only Deployment

### AWS: SCP (Service Control Policy)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Action": "*",
    "Resource": "*",
    "Condition": {
      "StringNotLike": {
        "aws:RequestedRegion": ["eu-*"]
      }
    }
  }]
}
```

### Terraform: Region Enforcement
```hcl
# In your root module — fail fast if region is not EU
variable "aws_region" {
  type = string
  validation {
    condition     = startswith(var.aws_region, "eu-")
    error_message = "Only EU regions allowed for GDPR/EU AI Act compliance."
  }
}
```

### GCP: Organization Policy
```bash
gcloud resource-manager org-policies set-policy \
  --organization=YOUR_ORG_ID \
  constraints/gcp.resourceLocations \
  --policy='{"constraint":"constraints/gcp.resourceLocations","listPolicy":{"allowedValues":["in:eu-locations"]}}'
```

## What "Data Residency" Actually Covers

| Data Type | Where it must stay | Why |
|-----------|-------------------|-----|
| Training data (personal) | EU | GDPR Art. 44 |
| Model weights | EU recommended | EU AI Act Art. 10 (data governance) |
| Inference logs with personal data | EU | GDPR Art. 44 |
| Audit logs (EU AI Act Art. 12) | EU | Art. 12 + GDPR |
| Model artifacts (non-personal) | Flexible | No hard requirement |

## S3/GCS Bucket Configuration (Terraform)

```hcl
resource "aws_s3_bucket" "ml_artifacts" {
  bucket = "your-ml-artifacts-eu"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ml_artifacts" {
  bucket = aws_s3_bucket.ml_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"  # Use KMS for GDPR compliance
    }
  }
}

# Enforce EU-only access
resource "aws_s3_bucket_policy" "ml_artifacts" {
  bucket = aws_s3_bucket.ml_artifacts.id
  policy = jsonencode({
    Statement = [{
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["${aws_s3_bucket.ml_artifacts.arn}/*"]
      Condition = {
        StringNotEquals = {
          "aws:SourceVpc" = var.vpc_id
        }
      }
    }]
  })
}
```

terraform {
  required_version = ">= 1.6"
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "ai-workloads/dev/terraform.tfstate"
    region = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "ai-workloads"
      ManagedBy   = "terraform"
    }
  }
}

module "gpu_cluster" {
  source        = "../../modules/gpu-cluster"
  cluster_name  = "ai-dev"
  instance_type = "g4dn.xlarge"
  min_size      = 0
  max_size      = 2
  desired_size  = 0  # Scale to zero when idle
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  ami_id        = var.gpu_ami_id
}

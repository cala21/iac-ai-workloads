# GPU Cluster Module for AI/ML Workloads
# Supports AWS (g4dn, p3, p4d), GCP (a2), Azure (NC-series)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "cluster_name" { type = string }
variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"  # 1x T4 GPU, cost-effective for inference
}
variable "min_size" { type = number; default = 0 }
variable "max_size" { type = number; default = 4 }
variable "desired_size" { type = number; default = 1 }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "ami_id" { type = string }  # Use Deep Learning AMI

resource "aws_launch_template" "gpu" {
  name_prefix   = "${var.cluster_name}-gpu-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-gpu-node"
      Workload    = "ai-inference"
      ManagedBy   = "terraform"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 required
    http_put_response_hop_limit = 1
  }
}

resource "aws_autoscaling_group" "gpu" {
  name             = "${var.cluster_name}-gpu-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_size
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.gpu.id
    version = "$Latest"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}

output "asg_name" { value = aws_autoscaling_group.gpu.name }
output "launch_template_id" { value = aws_launch_template.gpu.id }

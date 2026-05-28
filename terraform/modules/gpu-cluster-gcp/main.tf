# GPU Cluster Module — Google Cloud Platform
# Mirrors the AWS module interface for easy cross-cloud comparison
# Primary region: europe-west1 (Belgium) — EU data residency for GDPR/EU AI Act compliance

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "cluster_name" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "a2-highgpu-1g" # 1x A100 40GB. For T4: "n1-standard-4" + accelerator below
}

variable "accelerator_type" {
  type    = string
  default = "nvidia-tesla-a100"
  # Options: nvidia-tesla-t4, nvidia-tesla-v100, nvidia-tesla-a100, nvidia-l4
}

variable "accelerator_count" {
  type    = number
  default = 1
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 4
}

variable "region" {
  type    = string
  default = "europe-west1" # Belgium — broad service availability
  # Use europe-west8 (Milan) for lowest latency to Italian deployments
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "project_id" {
  type = string
}

variable "network" {
  type    = string
  default = "default"
}

variable "subnetwork" {
  type    = string
  default = "default"
}

resource "google_compute_instance_template" "gpu" {
  name_prefix  = "${var.cluster_name}-gpu-"
  machine_type = var.machine_type
  region       = var.region

  disk {
    source_image = "projects/deeplearning-platform-release/global/images/family/common-cu121"
    auto_delete  = true
    boot         = true
    disk_size_gb = 100
    disk_type    = "pd-ssd"
  }

  guest_accelerator {
    type  = var.accelerator_type
    count = var.accelerator_count
  }

  scheduling {
    on_host_maintenance = "TERMINATE" # Required for GPU instances
    automatic_restart   = true
    preemptible         = false
    # Set preemptible = true for ~80% cost reduction in dev/training
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    # No access_config block = no public IP (private cluster for compliance)
  }

  metadata = {
    "install-nvidia-driver" = "True"
    block-project-ssh-keys  = "true"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  labels = {
    workload    = "ai-inference"
    managed-by  = "terraform"
    data-region = "eu"
  }
}

resource "google_compute_region_instance_group_manager" "gpu" {
  name               = "${var.cluster_name}-gpu-mig"
  base_instance_name = "${var.cluster_name}-gpu"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.gpu.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.gpu.id
    initial_delay_sec = 120
  }
}

resource "google_compute_region_autoscaler" "gpu" {
  name   = "${var.cluster_name}-gpu-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.gpu.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 120

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_health_check" "gpu" {
  name = "${var.cluster_name}-gpu-health"
  http_health_check {
    port         = 8000
    request_path = "/health"
  }
}

output "instance_group" {
  value = google_compute_region_instance_group_manager.gpu.instance_group
}

output "template_id" {
  value = google_compute_instance_template.gpu.id
}

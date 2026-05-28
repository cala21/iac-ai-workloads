variable "aws_region" { type = string; default = "eu-west-1" }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "gpu_ami_id" { type = string }

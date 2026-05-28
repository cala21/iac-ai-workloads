variable "labels" {
  type    = map(string)
  default = {}
}

variable "enable_confidential_compute" {
  type    = bool
  default = false
  description = "Enable Confidential Computing for sensitive AI workloads (N2D only, no GPU support yet)"
}

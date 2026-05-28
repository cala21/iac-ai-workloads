variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_spot" {
  type    = bool
  default = false
  description = "Use Spot instances for 60-90% cost reduction (not recommended for production inference)"
}

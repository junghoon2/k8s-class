variable "environment_name" {
  type    = string
  default = "retail-store"
}

variable "istio_enabled" {
  description = "Boolean value that enables istio."
  type        = bool 
  default     = false
}
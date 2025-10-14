variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure location where the resources will be deployed."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A map of tags to assign to the resources."
}
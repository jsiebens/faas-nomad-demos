variable "project" {
  description = "The Project ID."
  type        = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "ip_range" {
  type    = string
  default = "10.10.10.0/24"
}
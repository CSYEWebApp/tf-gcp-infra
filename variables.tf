variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "vpcs" {
  description = "List of VPC configurations"
  type        = list(object({
    vpc_name              = string
    webapp_subnet         = string
    db_subnet             = string
    internet_gateway_name = string
    privateipgoogleaccess = bool
  }))
}

variable "application_port" {
  description = "The port on which the application listens"
  type        = number
}

variable "routing_mode" {
  description = "The routing mode for the network"
  type        = string
}

variable "custom_image" {
  description = "The custom image to use for the instance"
  type        = string
}

variable "disk_size_gb" {
  description = "The size of the boot disk in gigabytes"
  type        = number
}

variable "disk_type" {
  description = "The type of the boot disk"
  type        = string
}

variable "zone" {
  description = "The zone for the instance"
  type        = string
}

variable  "nexthopgateway" {
  description = "To set next hop gateway value"
  type        = string
}

variable "machine_type"{
  description = "The machine type for the instance"
  type        = string
}

variable "dest_range" {
  description = "The destination range for default route"
  type        = string
}


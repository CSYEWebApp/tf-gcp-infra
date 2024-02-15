variable "project_id" {
  description = "The ID of the GCP project."
}

variable "region" {
  description = "The region to deploy resources."
}

variable "vpcs" {
  description = "A list of objects representing VPC configurations."
  type        = list(object({
    name                  = string
    vpc_name              = string
    webapp_subnet         = string
    db_subnet             = string
    internet_gateway_name = string
  }))
}





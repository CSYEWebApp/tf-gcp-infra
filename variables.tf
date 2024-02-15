#terraform {
#  required_providers {
#    google = {
#      source  = "hashicorp/google"
#      version = "~> 4.0"
#    }
#  }
#}
#
#variable "project_id" {
#  description = "The ID of your GCP project"
#}
#
#variable "region" {
#  description = "The region where you want to create the VPC and subnets"
#}
#
#variable "vpc_name" {
#  description = "The name of your VPC network"
#}
#
#variable "internet_gateway_name" {
#  description = "The name of your internet gateway"
#}
#
#variable "webapp_subnet_cidr" {
#  description = "The CIDR range for the webapp subnet (/24 format)"
#}
#
#variable "db_subnet_cidr" {
#  description = "The CIDR range for the db subnet (/24 format)"
#}
#
#
#

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





variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

#variable "vpcs" {
#  description = "List of VPC configurations"
#  type        = list(object({
#    vpc_name              = string
#    webapp_subnet         = string
#    db_subnet             = string
#    internet_gateway_name = string
#    privateipgoogleaccess = bool
#  }))
#}

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

variable "nexthopgateway" {
  description = "To set next hop gateway value"
  type        = string
}

variable "machine_type" {
  description = "The machine type for the instance"
  type        = string
}

variable "dest_range" {
  description = "The destination range for default route"
  type        = string
}

variable "vpc_name" {
  description = "The VPC Name"
  type        = string
}
variable "webapp_subnet" {
  description = "Webapp subnet cidr"
  type        = string
}
variable "db_subnet" {
  description = "db subnet cidr"
  type        = string
}
variable "internet_gateway_name" {
  description = "internet gateway"
  type        = string
}
variable "privateipgoogleaccess" {
  description = "privateipgoogleaccess"
  type        = string
}

variable "sqlinstancename" {
  description = "gcloud sql instance name"
  type        = string
}
variable "database_version" {
  description = "databse version"
  type        = string

}

variable "tier" {
  description = "tier"
  type        = string

}

variable "availability_type" {
  description = "availability type"
  type        = string

}
variable "dbdisk_type" {
  description = "instance disk type"
  type        = string

}
variable "dbdisk_size" {
  description = "Database disk size"
  type        = number

}
variable "cloudsql_database_name" {
  description = "databse name"
  type        = string

}
variable "sql_user" {
  description = "sql user name"
  type        = string

}
variable "private_ip_address_name" {
  description = "private ip address name"
  type        = string

}
variable "ip_purpose" {
  description = "VPC purpose"
  type        = string

}
variable "ip_address_type" {
  description = "private ip address"
  type        = string
}

variable "username" {
  description = "SQL username"
  type        = string
}
variable "dbname" {
  description = "Database name"
  type        = string
}
variable "deletion_protection" {
  description = "Deletion protection"
  type        = bool
}
variable "ipv4_enabled" {
  description = "ipv4"
  type        = bool
}
variable "binary_log_enabled" {
  description = "binary log enabled"
  type        = bool
}
variable "backup_configuration_enabled" {
  description = "backup configuration for mySQL"
  type        = bool
}
variable "delete_default_routes_on_create" {
  description = "delete default routes on create"
  type        = bool
}
variable "auto_create_subnetworks" {
  description = "auto create subnetworks"
  type        = bool
}
variable "record_type" {
  description = "The type of DNS record (e.g., A, CNAME, TXT)"
  type        = string
}
variable "ttl" {
  description = "Time to live (TTL) for the DNS record"
  type        = number
}
variable "logging_admin_role" {
  description = "IAM role assigned to member"
  type        = string
}
variable "metric_writer_role" {
  description = "IAM role assigned to member"
  type        = string
}
variable "zone_name" {
  description = "The name of the existing DNS managed zone"
  type        = string
}
variable "service_account_account_id" {
  description = "The desired account ID for the service account"
  type        = string
}
variable "service_account_display_name" {
  description = "The desired display name for the service account"
  type        = string
}
variable "scopes" {
  description = "List of scopes for the service account"
  type        = list(string)
  #  default     = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
}

variable "api_key" {
  description = "Mailgun Api key"
  type        = string
}
variable "mailgun_email" {
  description = "mailgun email"
  type        = string
}
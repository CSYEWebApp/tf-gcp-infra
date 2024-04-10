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
variable "verificationBaseUrl" {
  description = "verificationlink"
  type = string
}

variable "request_path" {
  description = "request path"
  type = string
}
variable "healthcheck_port" {
  description = "healthcheck port"
  type = string
}
variable "base_instance_name" {
  description = "base_instance_name"
  type = string
}
variable "groupinstance_manager" {
  description = "group instance manager"
  type = string
}
variable "namedport_name" {
  description = "name of the named port"
  type = string
}
variable "namedport_port" {
  description = "port of the named port"
  type = number
}

variable "autoscaler_name" {
  description = "name of the autpscaler"
  type = string
}

variable "max_replicas" {
  description = "max replicas"
  type = number
}
variable "min_replicas" {
  description = "min replicas"
  type = number
}
variable "cooldown_period" {
  description = "cooldown period"
  type = number
}
variable "cpu_utilization_target" {
  description = "cpu utilization target"
  type = number
}
variable "target_proxy" {
  description = "webapp target proxy"
  type = string
}
variable "url_map" {
  description = "url map"
  type = string
}
variable "backend_service" {
  description = "backend service name"
  type = string
}
variable "load_balancing_scheme" {
  description = "load balancing scheme"
  type = string
}
variable "backend_port_name" {
  description = "port name"
  type = string
}
variable "backend_protocol" {
  description = "protocol"
  type = string
}

variable "backend_timeout_sec" {
  description = "timeout sec"
  type = number
}
variable "backend_balancing_mode" {
  description = "balancing mode"
  type = string
}
variable "forwarding_rule_name" {
  description = "forwarding rule"
  type = string
}
variable "forwarding_rule_port_range" {
  description = "port range"
  type = string
}
variable "lb_default_cert_name" {
  description = "load balancing certificate name"
  type = string
}
variable "lb_default_cert_type" {
  description = "load balancing certificate types"
  type = string
}
variable "health_check_name" {
  description = "health check name"
  type = string
}
variable "check_interval_sec" {
  description = "check interval sec"
  type = number
}
variable "timeout_sec" {
  description = "timeout sec"
  type = number
}
variable "healthy_threshold" {
  description = "healthy threshold"
  type = number
}
variable "unhealthy_threshold" {
  description = "unhealthy threshold"
  type = number
}
variable "bucket_archive_source" {
  description = "bucket archive"
  type = string
}
variable "cloud_function_entrypoint" {
  description = "entry point for cloud function"
  type = string
}
variable "ack_deadline_seconds" {
  description = "ack deadline seconds"
  type = number
}
variable "message_retention_duration" {
  description = "message retention duration"
  type = string
}
variable "pubtopicname" {
  description = "pub topic name"
  type = string
}
variable "pubsub_subscription_name" {
  description = "pubsub_subscription_name"
  type = string
}

variable "cloud_location" {
  description = "location"
  type = string
}
variable "uniform_bucket_level_access" {
  description = "uniform bucket level access"
  type = bool
}
variable "cloud_bucket_name" {
  description = "cloud bucket name"
  type = string
}
variable "runtime" {
  description = "runtime"
  type = string
}
variable "min_instance_count" {
  description = "min instance count"
  type = number
}
variable "max_instance_count" {
  description = "max instance count"
  type = number
}
variable "available_memory" {
  description = "available memory"
  type = string
}
variable "max_instance_request_concurrency" {
  description = "max_instance_request_concurrency"
  type = number
}
variable "available_cpu" {
  description = "available cpu"
  type = string
}
variable "vpc_connector_egress_settings" {
  description = "vpc_connector_egress_settings"
  type = string
}
variable "event_type" {
  description = "event type"
  type = string
}
variable "retry_policy" {
  description = "retry policy"
  type = string
}
variable "ip_cidr_range" {
  description = "ip cidr range"
  type = string
}
variable "serverlessvpc_name" {
  description = "serverless_name"
  type = string
}
variable "cloudfunction_service_account_id" {
  description = "cloudfunction service account id"
  type = string
}
variable "cloudfunction_service_display_anme" {
  description = "cloudfunction service display name"
  type = string
}
variable "pubsub_binding_role" {
  description = "pubsub binding role"
  type = string
}
variable "invoker_binding_role" {
  description = "invoker binding role"
  type = string
}
variable "pubsub_publisher_binding_role" {
  description = "pubsub publisher binding role"
  type = string
}

variable "vm_crypto_key_name" {
  description = "Name for the VM crypto key"
  type        = string

}

variable "cloudsql_crypto_key_name" {
  description = "Name for the CloudSQL crypto key"
  type        = string
}

variable "storage_crypto_key_name" {
  description = "Name for the storage crypto key"
  type        = string
}
variable "crypto_key_purpose" {
  description = "Purpose for the crypto key"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "crypto_key_rotation_period" {
  description = "Rotation period for the crypto key"
  type        = string
  default     = "2592000s" # Rotation period of 30 days
}

variable "vm_crypto_key_role" {
  description = "Role for the VM crypto key IAM binding"
  type        = string
}

variable "cloudsql_crypto_key_role" {
  description = "Role for the CloudSQL crypto key IAM binding"
  type        = string
}

variable "storage_crypto_key_role" {
  description = "Role for the storage crypto key IAM binding"
  type        = string
}


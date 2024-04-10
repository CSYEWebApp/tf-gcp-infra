terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      #      version = "5.22.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_project" "project_number"{
}

resource "google_compute_network" "vpc_network" {
  name                            = var.vpc_name
  delete_default_routes_on_create = var.delete_default_routes_on_create
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name                     = "${var.vpc_name}-webapp-subnet"
  ip_cidr_range            = var.webapp_subnet
  region                   = var.region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = var.privateipgoogleaccess
}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = "${var.vpc_name}-db-subnet"
  ip_cidr_range            = var.db_subnet
  region                   = var.region
  network                  = google_compute_network.vpc_network.self_link
  private_ip_google_access = var.privateipgoogleaccess
}

resource "google_compute_global_address" "private_ip_address" {
  name          = var.private_ip_address_name
  purpose       = var.ip_purpose
  address_type  = var.ip_address_type
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "cloudsql_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  deletion_policy         = "ABANDON"
}

resource "google_compute_route" "default_route" {
  name             = "${var.vpc_name}-default-route"
  network          = google_compute_network.vpc_network.self_link
  dest_range       = var.dest_range
  next_hop_gateway = var.nexthopgateway
  priority         = 1000
}

resource "google_compute_firewall" "webapp_allow_rule" {
  name    = "${var.vpc_name}-webapp-allow-rule"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["my-vm"]
}

resource "google_compute_firewall" "webapp_deny_rule" {
  name    = "${var.vpc_name}-webapp-deny-rule"
  network = google_compute_network.vpc_network.name

  # Deny SSH from the internet
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["my-vm"]
}
resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project = var.project_id
  service  = "sqladmin.googleapis.com"
}


resource "google_sql_database_instance" "sql_instance" {
  name                = var.sqlinstancename
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection
  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = "projects/${var.project_id}/global/networks/${google_compute_network.vpc_network.name}"
    }
    availability_type = var.availability_type
    disk_type         = var.dbdisk_type
    disk_size         = var.dbdisk_size
    backup_configuration {
      binary_log_enabled = var.binary_log_enabled
      enabled            = var.backup_configuration_enabled
    }
  }
  encryption_key_name = google_kms_crypto_key.cloudsql_crypto_key.id
  depends_on = [google_service_networking_connection.cloudsql_connection]
}

resource "google_sql_database" "cloudsql_database" {
  name     = var.cloudsql_database_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name       = var.sql_user
  instance   = google_sql_database_instance.sql_instance.name
  password   = random_password.cloudsql_password.result
  depends_on = [google_sql_database_instance.sql_instance]
}

resource "random_password" "cloudsql_password" {
  length  = 16
  special = true
  override_special = "-@&4"
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
}

# Create Key Ring for the region
resource "google_kms_key_ring" "my_key_ring" {
  name     = "my-key-ring4"
  location = var.region
}

# Create Encryption Key for Virtual Machines
resource "google_kms_crypto_key" "vm_crypto_key" {
  name       = var.vm_crypto_key_name
  key_ring   = google_kms_key_ring.my_key_ring.id
  purpose    = var.crypto_key_purpose
  rotation_period = var.crypto_key_rotation_period# Rotation period of 30 days
}

# Create Encryption Key for CloudSQL Instances
resource "google_kms_crypto_key" "cloudsql_crypto_key" {
  name       = var.cloudsql_crypto_key_name
  key_ring   = google_kms_key_ring.my_key_ring.id
  purpose    = var.crypto_key_purpose
  rotation_period = var.crypto_key_rotation_period # Rotation period of 30 days
}

# Create Encryption Key for Cloud Storage Buckets
resource "google_kms_crypto_key" "storage_crypto_key" {
  name       = var.storage_crypto_key_name
  key_ring   = google_kms_key_ring.my_key_ring.id
  purpose    = var.crypto_key_purpose
  rotation_period = var.crypto_key_rotation_period # Rotation period of 30 days
}

resource "google_kms_crypto_key_iam_binding" "cloudsql_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.cloudsql_crypto_key.id
  role          = var.cloudsql_crypto_key_role
  members       = ["serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}"]
}

resource "google_kms_crypto_key_iam_binding" "storage_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.storage_crypto_key.id
  role          = var.storage_crypto_key_role
  members       = ["serviceAccount:service-${data.google_project.project_number.number}@gs-project-accounts.iam.gserviceaccount.com"]
}

resource "google_kms_crypto_key_iam_binding" "vm_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.vm_crypto_key.id
  role          = var.vm_crypto_key_role
  members       = ["serviceAccount:service-${data.google_project.project_number.number}@compute-system.iam.gserviceaccount.com"]
}

#resource "google_compute_instance" "webapp_instance" {
#  name         = "${var.vpc_name}-webapp-instance"
#  machine_type = var.machine_type
#  zone         = var.zone
#  tags         = ["my-vm"]
#  boot_disk {
#    initialize_params {
#      image = var.custom_image
#      size  = var.disk_size_gb
#      type  = var.disk_type
#    }
#  }
#  network_interface {
#    network    = google_compute_network.vpc_network.name
#    subnetwork = google_compute_subnetwork.webapp_subnet.name
#
#    access_config {
#
#    }
#  }
#
#  metadata_startup_script = <<-EOF
#      #!/bin/bash
#
#      > /opt/csye6225/application.properties
#      echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.sql_instance.private_ip_address}:3306/${var.dbname}?createDatabaseIfNotExist=true" >> /opt/csye6225/application.properties
#      echo "spring.datasource.username=${var.username}" >> /opt/csye6225/application.properties
#      echo "spring.datasource.password=${random_password.cloudsql_password.result}" >> /opt/csye6225/application.properties
#      echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/csye6225/application.properties
#      echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect" >> /opt/csye6225/application.properties
#      echo "spring.jackson.deserialization.fail-on-unknown-properties=true" >> /opt/csye6225/application.properties
#      echo "projectId=dev-csye-6225-415001" >> /opt/csye6225/application.properties
#      echo "topicId=verify_email >>/opt/csye6225/application.properties
#  EOF
#
#  depends_on = [google_service_account.service_account]
#
#  service_account {
#    email  = google_service_account.service_account.email
#    scopes = var.scopes
#  }
#  allow_stopping_for_update = true
#}


resource "google_compute_region_instance_template" "webappinstance_template" {
  name         = "${var.vpc_name}-webapp-instance"
  #  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["my-vm"]

  disk {

    source_image = var.custom_image
    #    size  = var.disk_size_gb
    type  = var.disk_type
    boot  = true
    disk_encryption_key {
      #      kms_key_name = google_kms_crypto_key.vm_crypto_key.id
      kms_key_self_link = google_kms_crypto_key.vm_crypto_key.id
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.webapp_subnet.name

    access_config {

    }
  }

  metadata_startup_script = <<-EOF
        #!/bin/bash

        > /opt/csye6225/application.properties
        echo "spring.datasource.url=jdbc:mysql://${google_sql_database_instance.sql_instance.private_ip_address}:3306/${var.dbname}?createDatabaseIfNotExist=true" >> /opt/csye6225/application.properties
        echo "spring.datasource.username=${var.username}" >> /opt/csye6225/application.properties
        echo "spring.datasource.password=${random_password.cloudsql_password.result}" >> /opt/csye6225/application.properties
        echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/csye6225/application.properties
        echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect" >> /opt/csye6225/application.properties
        echo "spring.jackson.deserialization.fail-on-unknown-properties=true" >> /opt/csye6225/application.properties
        echo "projectId=dev-csye-6225-415001" >> /opt/csye6225/application.properties
        echo "topicId=verify_email" >>/opt/csye6225/application.properties
    EOF

  depends_on = [google_service_account.service_account]

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
  #  allow_stopping_for_update = true
}

resource "google_compute_health_check" "health_check" {
  name                = var.health_check_name
  check_interval_sec  = var.check_interval_sec
  timeout_sec         = var.timeout_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    request_path = var.request_path
    port         = var.healthcheck_port
  }
}
resource "google_compute_region_instance_group_manager" "instance_group_manager" {
  base_instance_name = var.base_instance_name
  name               = var.groupinstance_manager
  region             = var.region
  named_port {
    name = var.namedport_name
    port = var.namedport_port
  }
  #  zone = var.zone
  distribution_policy_zones  = ["us-central1-a", "us-central1-b"]
  target_size = 1

  version {
    instance_template = google_compute_region_instance_template.webappinstance_template.self_link
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.id
    initial_delay_sec = 150
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  name   = var.autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.instance_group_manager.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.cpu_utilization_target
    }
  }
}


resource "google_compute_target_https_proxy" "target_proxy" {
  name    = var.target_proxy
  url_map = google_compute_url_map.url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_default_cert.id]
}

resource "google_compute_url_map" "url_map" {
  name             = var.url_map
  default_service  = google_compute_backend_service.backend_service.self_link
}

output "instance_group_url" {
  value = google_compute_region_instance_group_manager.instance_group_manager.instance_group
}

resource "google_compute_backend_service" "backend_service" {
  name          = var.backend_service
  load_balancing_scheme = var.load_balancing_scheme
  port_name     = var.backend_port_name
  protocol      = var.backend_protocol
  timeout_sec   = var.backend_timeout_sec
  health_checks = [google_compute_health_check.health_check.id]
  backend {
    group = google_compute_region_instance_group_manager.instance_group_manager.instance_group
    balancing_mode = var.backend_balancing_mode
    capacity_scaler = 1.0
  }
}

resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name       = var.forwarding_rule_name
  target     = google_compute_target_https_proxy.target_proxy.self_link
  port_range = var.forwarding_rule_port_range
  ip_address = google_compute_global_address.webapp_ip.address
}

resource "google_compute_managed_ssl_certificate" "lb_default_cert" {
  name = var.lb_default_cert_name
  type = var.lb_default_cert_type
  managed {
    domains = ["csye6225cloud.me"]
  }
}

resource "google_compute_global_address" "webapp_ip" {
  name = "webapp-global-ip1"
}


data "google_dns_managed_zone" "existing_zone" {
  name = var.zone_name
}

resource "google_dns_record_set" "a" {
  name         = data.google_dns_managed_zone.existing_zone.dns_name
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  type         = var.record_type
  ttl          = var.ttl
  rrdatas      = [google_compute_global_address.webapp_ip.address]
}

resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role    = var.logging_admin_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer_binding" {
  project = var.project_id
  role    = var.metric_writer_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_pubsub_topic" "pubtopic" {
  name = var.pubtopicname
  message_retention_duration = var.message_retention_duration
}

resource "google_pubsub_subscription" "pusub" {
  name                 = var.pubsub_subscription_name
  topic                = google_pubsub_topic.pubtopic.id
  ack_deadline_seconds = var.ack_deadline_seconds
}
resource "google_storage_bucket" "cloud_bucket" {
  name                        = var.cloud_bucket_name
  location                    = var.cloud_location
  uniform_bucket_level_access = var.uniform_bucket_level_access
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_crypto_key.id
  }
  depends_on = [google_kms_crypto_key_iam_binding.storage_crypto_key_binding]
}

resource "google_storage_bucket_object" "archive" {
  name   = "function.jar"
  bucket = google_storage_bucket.cloud_bucket.name
  source = var.bucket_archive_source
}

resource "google_cloudfunctions2_function" "cloud_function" {
  name        = "cloudfunction"
  location    = var.region
  description = "abcd"

  depends_on = [google_vpc_access_connector.serverlessvpc, google_sql_database_instance.sql_instance]
  build_config {
    runtime     = var.runtime
    entry_point = var.cloud_function_entrypoint

    source {
      storage_source {
        bucket = google_storage_bucket.cloud_bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    min_instance_count               = var.min_instance_count
    max_instance_count               = var.max_instance_count
    available_memory                 = var.available_memory
    max_instance_request_concurrency = var.max_instance_request_concurrency
    available_cpu                    = var.available_cpu
    service_account_email            = google_service_account.cloudfunction_service.email
    environment_variables = {
      dbUrl = "jdbc:mysql://${google_sql_database_instance.sql_instance.private_ip_address}:3306/webapp?createDatabaseIfNotExist=true"
      #      db_ip ="${google_sql_database_instance.sql_instance.private_ip_address}"
      dbName        = google_sql_database.cloudsql_database.name
      dbPass        = random_password.cloudsql_password.result
      mailgun_email = var.mailgun_email
      api_key       = var.api_key
      verificationBaseUrl = var.verificationBaseUrl
    }

    vpc_connector                 = "projects/${var.project_id}/locations/${var.region}/connectors/${google_vpc_access_connector.serverlessvpc.name}"
    vpc_connector_egress_settings = var.vpc_connector_egress_settings

  }
  #  vpc
  event_trigger {

    trigger_region = var.region
    event_type     = var.event_type
    pubsub_topic   = google_pubsub_topic.pubtopic.id
    retry_policy   = var.retry_policy
  }
}

resource "google_vpc_access_connector" "serverlessvpc" {
  project       = var.project_id
  name          = var.serverlessvpc_name
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = var.ip_cidr_range
}


resource "google_service_account" "cloudfunction_service" {
  account_id   = var.cloudfunction_service_account_id
  display_name = var.cloudfunction_service_display_anme
}

resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  project = var.project_id
  role    = var.pubsub_binding_role
  topic   = google_pubsub_topic.pubtopic.name
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]

}

resource "google_project_iam_binding" "invoker_binding" {
  members = ["serviceAccount:${google_service_account.cloudfunction_service.email}"]
  project = var.project_id
  role    = var.invoker_binding_role
}

resource "google_project_iam_binding" "pubsub_publisher_binding" {
  project = var.project_id
  role    = var.pubsub_publisher_binding_role
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}
#resource "google_service_account_iam_member" "member_service" {
#  service_account_id = google_service_account.cloudfunction_service.account_id
#  role     = "roles/iam.serviceAccountUser"
#  member = google_service_account.cloudfunction_service
#}




output "nat_ip_value" {
  value = google_compute_region_instance_template.webappinstance_template.network_interface[0].access_config[0].nat_ip
}







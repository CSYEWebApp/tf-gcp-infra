terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
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
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
}

resource "google_compute_instance" "webapp_instance" {
  name         = "${var.vpc_name}-webapp-instance"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["my-vm"]
  boot_disk {
    initialize_params {
      image = var.custom_image
      size  = var.disk_size_gb
      type  = var.disk_type
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
      echo "topicId=pub-topic >>/opt/csye6225/application.properties
  EOF

  depends_on = [google_service_account.service_account]

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
  allow_stopping_for_update = true
}

data "google_dns_managed_zone" "existing_zone" {
  name = var.zone_name
}

resource "google_dns_record_set" "a" {
  name         = data.google_dns_managed_zone.existing_zone.dns_name
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  type         = var.record_type
  ttl          = var.ttl
  rrdatas      = [google_compute_instance.webapp_instance.network_interface[0].access_config[0].nat_ip]
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
  name = "verify_email"

  message_retention_duration = "604800s"
}

resource "google_pubsub_subscription" "pusub" {
  name  = "pubsub-subscription"
  topic = google_pubsub_topic.pubtopic.id
  ack_deadline_seconds = 20
}
resource "google_storage_bucket" "cloud_bucket" {
  name     = "abcxyz7686"
  location = "US"
  uniform_bucket_level_access = false
}

resource "google_storage_bucket_object" "archive" {
  name   = "function.jar"
  bucket = google_storage_bucket.cloud_bucket.name
  source = "/Users/vamsidhar/Documents/CloudFunctionSource/function-source.zip"

}

resource "google_cloudfunctions2_function" "cloud_function" {
  name = "cloudfunction"
  location = var.region
  description = "abcd"

  depends_on = [google_vpc_access_connector.serverlessvpc, google_sql_database_instance.sql_instance]
  build_config {
    runtime = "java17"
    entry_point = "gcfv2pubsub.PubSubFunction"

    source {
      storage_source {
        bucket = google_storage_bucket.cloud_bucket.name
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    min_instance_count = 0
    max_instance_count = 1
    available_memory = "2Gi"
    max_instance_request_concurrency = 10
    available_cpu = "2"
    service_account_email = google_service_account.cloudfunction_service.email
    environment_variables = {
      db_ip ="${google_sql_database_instance.sql_instance.private_ip_address}"
      password ="${random_password.cloudsql_password.result}"
      mailgun_email = "postmaster@csye6225cloud.me"
      api_key = "5b3158fa7599ba7c4c4d36863c382484-f68a26c9-6574ecb1"
    }

    vpc_connector = "projects/${var.project_id}/locations/${var.region}/connectors/${google_vpc_access_connector.serverlessvpc.name}"
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"

  }
  #  vpc
  event_trigger {

    trigger_region = var.region
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.pubtopic.id
    retry_policy = "RETRY_POLICY_DO_NOT_RETRY"
  }
}

resource "google_vpc_access_connector" "serverlessvpc" {
  project = var.project_id
  name = "vpcconnectorx"
  region = var.region
  network = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.8.0/28"
}


resource "google_service_account" "cloudfunction_service" {
  account_id = "cloud-sa"
  display_name = "cloud service account"
}

resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  project = var.project_id
  role    = "roles/pubsub.publisher"  # or any other suitable Pub/Sub role
  topic = google_pubsub_topic.pubtopic.name
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]

}

resource "google_project_iam_binding" "invoker_binding" {
  members = ["serviceAccount:${google_service_account.cloudfunction_service.email}"]
  project = var.project_id
  role    = "roles/run.invoker"
}
#resource "google_service_account_iam_member" "member_service" {
#  service_account_id = google_service_account.cloudfunction_service.account_id
#  role     = "roles/iam.serviceAccountUser"
#  member = google_service_account.cloudfunction_service
#}












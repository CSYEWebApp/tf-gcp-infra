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
  EOF
}


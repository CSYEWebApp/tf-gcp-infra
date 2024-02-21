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
  count                           = length(var.vpcs)
  name                            = var.vpcs[count.index].vpc_name
  delete_default_routes_on_create = true
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
}

resource "google_compute_subnetwork" "webapp_subnet" {
  count             = length(var.vpcs)
  name              = "${var.vpcs[count.index].vpc_name}-webapp-subnet"
  ip_cidr_range     = var.vpcs[count.index].webapp_subnet
  region            = var.region
  network           = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = var.vpcs[count.index].privateipgoogleaccess
}

resource "google_compute_subnetwork" "db_subnet" {
  count             = length(var.vpcs)
  name              = "${var.vpcs[count.index].vpc_name}-db-subnet"
  ip_cidr_range     = var.vpcs[count.index].db_subnet
  region            = var.region
  network           = google_compute_network.vpc_network[count.index].self_link
  private_ip_google_access = var.vpcs[count.index].privateipgoogleaccess

}


resource "google_compute_route" "default_route" {
  count               = length(var.vpcs)
  name                = "${var.vpcs[count.index].vpc_name}-default-route"
  network             = google_compute_network.vpc_network[count.index].self_link
  dest_range          = var.dest_range
  next_hop_gateway    = var.nexthopgateway
  priority            = 1000
}

resource "google_compute_firewall" "webapp_allow_rule" {
  count     = length(var.vpcs)
  name      = "${var.vpcs[count.index].vpc_name}-webapp-allow-rule"
  network   = google_compute_network.vpc_network[count.index].name

  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["my-vm"]
}

resource "google_compute_firewall" "webapp_deny_rule" {
  count     = length(var.vpcs)
  name      = "${var.vpcs[count.index].vpc_name}-webapp-deny-rule"
  network   = google_compute_network.vpc_network[count.index].name

  # Deny SSH from the internet
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["my-vm"]
}
resource "google_compute_instance" "webapp_instance" {
  count         = length(var.vpcs)
  name          = "${var.vpcs[count.index].vpc_name}-webapp-instance"
  machine_type  = var.machine_type
  zone          = var.zone
  tags = ["my-vm"]
  boot_disk {
    initialize_params {
      image = var.custom_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    network = google_compute_network.vpc_network[count.index].name
    subnetwork = google_compute_subnetwork.webapp_subnet[count.index].name

    access_config {

    }
  }
}


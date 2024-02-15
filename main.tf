provider "google" {
  project = var.project_id
  region  = var.region
}
resource "google_compute_network" "vpc_network" {
  count                           = length(var.vpcs)
  name                            = var.vpcs[count.index].vpc_name
  delete_default_routes_on_create = true
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
}
resource "google_compute_subnetwork" "webapp_subnet" {
  count             = length(var.vpcs)
  name              = "${var.vpcs[count.index].vpc_name}-webapp-subnet"
  ip_cidr_range     = var.vpcs[count.index].webapp_subnet
  region            = var.region
  network           = google_compute_network.vpc_network[count.index].self_link
}
resource "google_compute_subnetwork" "db_subnet" {
  count             = length(var.vpcs)
  name              = "${var.vpcs[count.index].vpc_name}-db-subnet"
  ip_cidr_range     = var.vpcs[count.index].db_subnet
  region            = var.region
  network           = google_compute_network.vpc_network[count.index].self_link
}
resource "google_compute_global_address" "internet_gateway_ip" {
  count = length(var.vpcs)
  name  = var.vpcs[count.index].internet_gateway_name
}
locals {
  next_hop_ips = [
    for vpc in var.vpcs : cidrhost(vpc.webapp_subnet, 1)
  ]
}
resource "google_compute_route" "default_route" {
  count               = length(var.vpcs)
  name                = "${var.vpcs[count.index].vpc_name}-default-route"
  network             = google_compute_network.vpc_network[count.index].self_link
  dest_range          = "0.0.0.0/0"
  next_hop_ip         = local.next_hop_ips[count.index]
  priority            = 1000
}









# terraform/main.tf

provider "google" {
  project = "gcp-wow-wiq-017-test"
  region  = "us-central1"
}

# 1. VPC Network
resource "google_compute_network" "vpc" {
  name = "app-network"
}

# 2. Private IP range for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "google-managed-services-default"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# 3. Connect VPC to Google Services (for Private SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# 4. Cloud SQL Instance (Private)
resource "google_sql_database_instance" "db" {
  name             = "three-tier-db"
  database_version = "POSTGRES_15"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

# 5. Serverless VPC Access Connector (Allows Cloud Run to talk to Private SQL)
resource "google_vpc_access_connector" "connector" {
  name          = "run-to-db"
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"
  region        = "us-central1"
}

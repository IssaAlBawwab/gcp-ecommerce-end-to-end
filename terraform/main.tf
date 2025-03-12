terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.25.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Cloud Storage Bucket
resource "google_storage_bucket" "data_lake_bucket" {
  name          = "${var.data_lake_bucket_name_prefix}-${var.gcp_project_id}"
  location      = var.gcp_region
  storage_class = "STANDARD"
}

output "data_lake_bucket_name" {
  value = google_storage_bucket.data_lake_bucket.name
  description = "Name of the Cloud Storage Data Lake bucket"
}
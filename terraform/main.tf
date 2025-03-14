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

resource "google_bigquery_dataset" "default" {
  project                     = var.gcp_project_id
  dataset_id                  = var.dataset_id
  description                 = "Dataset that holds all ecom-events related tables"
  location                    = var.gcp_region
  default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = var.table_id

  time_partitioning {
    type = "DAY"
    field = "event_time"
  }

  clustering = [ "event_type","product_id", "category_code" ]

 schema = jsonencode([
  {
    "name" : "event_time",
    "type" : "TIMESTAMP",
    "mode" : "NULLABLE"
  },
  {
    "name" : "event_type",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "product_id",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "category_id",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "category_code",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "brand",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "price",
    "type" : "FLOAT64",
    "mode" : "NULLABLE"
  },
  {
    "name" : "user_id",
    "type" : "STRING",
    "mode" : "NULLABLE"
  },
  {
    "name" : "user_session",
    "type" : "STRING",
    "mode" : "NULLABLE"
  }
])

}


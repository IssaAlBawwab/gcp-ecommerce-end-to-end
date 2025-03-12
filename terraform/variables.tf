variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region to deploy resources in"
  default     = "us-central1"
}

variable "data_lake_bucket_name_prefix" {
  type        = string
  description = "Prefix for the Cloud Storage Data Lake bucket name (will be made globally unique)"
  default     = "ecom-data-lake-bucket"
}
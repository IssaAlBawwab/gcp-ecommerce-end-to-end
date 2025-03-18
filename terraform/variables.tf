variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region to deploy resources in"
  default     = "us-central1"
}

variable "dataset_id" {
  type        = string
  description = "Dataset ID for bigquery"
  default = "ecom_events"
}

variable "table_id" {
  type        = string
  description = "Table ID for bigquery"
  default = "kafka_ecom_events"
}

variable "compute_instance" {
  type = string
  description = "Compute instance name"
  default = "producer-consumer"
}


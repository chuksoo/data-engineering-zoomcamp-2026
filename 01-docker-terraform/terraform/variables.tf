variable "credentials" {
  description = "My GCP Credentials"
  default     = "./keys/my-creds.json"
}

variable "project" {
  description = "Project"
  default     = "terraform-dezoomcamp-485401"
}

variable "region" {
  description = "Region"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "The name of the BigQuery dataset"
  default     = "dezoomcamp_dataset"
}

variable "gcs_bucket_name" {
  description = "The name of the GCS bucket"
  default     = "terraform-dezoomcamp-485401-bucket"
}

variable "gcs_storage_class" {
  description = "The storage class of the GCS bucket"
  default     = "STANDARD"
}
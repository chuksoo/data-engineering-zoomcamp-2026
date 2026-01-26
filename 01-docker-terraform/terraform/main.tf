terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  # credentials = file("./keys/my-creds.json") 
  project = "terraform-dezoomcamp-485401"
  region  = "us-central1"
}

resource "google_storage_bucket" "dezoomcamp-bucket" {
  name          = "terraform-dezoomcamp-485401-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  project = "terraform-dezoomcamp-485401"
  region  = "us-central1"
}
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# This tells Terraform to expect an API token
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

provider "digitalocean" {
  token = var.do_token
}

# Automatically find the latest Kubernetes version supported by DO
data "digitalocean_kubernetes_versions" "latest" {}

# The blueprint for your actual cluster
resource "digitalocean_kubernetes_cluster" "staging_cluster" {
  name    = "transit-staging"
  region  = "sgp1"
  version = data.digitalocean_kubernetes_versions.latest.latest_version

  node_pool {
    name       = "worker"
    size       = "s-4vcpu-8gb"
    node_count = 3
  }
}
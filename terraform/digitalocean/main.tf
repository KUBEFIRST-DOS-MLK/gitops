terraform {
  backend "s3" {
    endpoint = "nyc3.digitaloceanspaces.com"
    key      = "terraform/digitalocean/terraform.tfstate"
    bucket   = "k1-state-store-installer-elzl52"
    // Don't change this.
    region = "us-east-1"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {
  type = string
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  cluster_name         = "installer"
  pool_name            = "${local.cluster_name}-node-pool"
  kube_config_filename = "../../../kubeconfig"
}

data "digitalocean_kubernetes_versions" "versions" {
  version_prefix = "1.27."
}

resource "digitalocean_kubernetes_cluster" "kubefirst" {
  name    = local.cluster_name
  region  = lower(var.region)
  version = data.digitalocean_kubernetes_versions.versions.latest_version

  node_pool {
    name       = local.pool_name
    size       = "s-4vcpu-8gb"
    node_count = tonumber("4") # tonumber() is used for a string token value
  }
}

resource "local_file" "kubeconfig" {
  content  = digitalocean_kubernetes_cluster.kubefirst.kube_config.0.raw_config
  filename = local.kube_config_filename
}

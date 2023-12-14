terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "0.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

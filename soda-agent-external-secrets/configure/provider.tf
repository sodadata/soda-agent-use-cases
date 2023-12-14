provider "helm" {
  kubernetes {
    config_path = pathexpand("${path.module}/../setup/${data.terraform_remote_state.setup.outputs.cluster_name}-config")
  }
}

provider "vault" {
  token   = data.terraform_remote_state.setup.outputs.vault_root_token
  address = "http://127.0.0.1:${data.terraform_remote_state.setup.outputs.base_port}"
}

provider "kubernetes" {
  config_path = pathexpand("${path.module}/../setup/${data.terraform_remote_state.setup.outputs.cluster_name}-config")
}

provider "kubectl" {
  config_path = pathexpand("${path.module}/../setup/${data.terraform_remote_state.setup.outputs.cluster_name}-config")
}

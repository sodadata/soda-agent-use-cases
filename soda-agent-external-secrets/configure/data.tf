data "terraform_remote_state" "setup" {
  backend = "local"

  config = {
    path = "../setup/terraform.tfstate"
  }
}

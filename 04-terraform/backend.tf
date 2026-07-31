terraform {
  backend "s3" {
    bucket       = "fabian-homelab-tfstate-us-east-1"
    key          = "aws-container-platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
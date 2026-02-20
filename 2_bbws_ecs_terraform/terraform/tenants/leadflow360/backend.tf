terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "tenants/leadflow360/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "bbws-terraform-locks-dev"
  }
}

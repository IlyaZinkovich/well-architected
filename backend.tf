terraform {
  backend "s3" {
    bucket         = "well-architected-terraform-backend-state"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "well-architected-terraform-backend-lock"
  }
}

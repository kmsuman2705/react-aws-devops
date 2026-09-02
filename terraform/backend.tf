terraform {
  backend "s3" {
    bucket = "suman-react-devops-terraform-state-2026"
    key    = "react-aws-devops/terraform.tfstate"
    region = "ap-south-1"
  }
}

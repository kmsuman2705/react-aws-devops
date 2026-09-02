resource "aws_s3_bucket" "terraform_state" {
  bucket = "suman-react-devops-terraform-state-2026"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

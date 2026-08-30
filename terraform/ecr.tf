resource "aws_ecr_repository" "react_app" {
  name                 = "react-devops"
  image_tag_mutability = "MUTABLE"

  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "react-devops-ecr"
    Environment = "dev"
    Project     = "react-devops"
  }
}

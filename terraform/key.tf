resource "aws_key_pair" "react_devops" {
  key_name   = "react-devops-key"
  public_key = file("${pathexpand("~/.ssh/react-devops-key.pub")}")
}

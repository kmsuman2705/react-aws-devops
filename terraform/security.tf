resource "aws_security_group" "web" {
  name        = "react-devops-web-sg"
  description = "Security group for React application"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "react-devops-web-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "49.47.134.75/32"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

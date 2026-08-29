data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    set -e

    # Update packages
    apt-get update -y

    # Install Docker
    apt-get install -y docker.io

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Install SSM Agent
    snap install amazon-ssm-agent --classic

    # Enable and start SSM Agent
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

  EOF

  tags = {
    Name = "react-devops-web"
  }
}

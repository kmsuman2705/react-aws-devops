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
  key_name                    = aws_key_pair.react_devops.key_name

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash

    # Send user-data output to log
    exec > /var/log/user-data.log 2>&1

    # Exit on errors, undefined variables, and failed pipes
    set -euxo pipefail

    echo "=== USER DATA STARTED ==="

    # Update package index
    apt-get update -y

    # Install Docker and Nginx
    apt-get install -y docker.io nginx

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx

    # Add ubuntu user to Docker group
    usermod -aG docker ubuntu

    # Install Amazon SSM Agent
    snap install amazon-ssm-agent --classic

    # Enable and start SSM Agent
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

    # Verify services
    systemctl is-active --quiet docker
    systemctl is-active --quiet nginx
    systemctl is-active --quiet snap.amazon-ssm-agent.amazon-ssm-agent.service

    echo "USER_DATA_COMPLETED" > /tmp/user-data-completed

    echo "=== USER DATA FINISHED ==="
  EOF

  tags = {
    Name = "react-devops-web"
  }
}

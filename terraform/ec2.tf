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

    exec > /var/log/user-data.log 2>&1
    set -euxo pipefail

    echo "=== USER DATA STARTED ==="

    apt-get update -y

    # Docker + Nginx + required packages
    apt-get install -y docker.io nginx curl unzip

    # Docker
    systemctl enable docker
    systemctl start docker

    # Ubuntu user -> Docker group
    usermod -aG docker ubuntu

    # AWS CLI v2
    curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
      -o /tmp/awscliv2.zip

    unzip -q /tmp/awscliv2.zip -d /tmp

    /tmp/aws/install

    /usr/local/bin/aws --version

    # Nginx reverse proxy
    cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

    nginx -t

    systemctl enable nginx
    systemctl restart nginx

    # SSM Agent
    snap install amazon-ssm-agent --classic || true

    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

    # Verification
    docker --version
    nginx -v
    /usr/local/bin/aws --version

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

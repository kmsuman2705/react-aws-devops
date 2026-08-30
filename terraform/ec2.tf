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

echo "=== USER DATA START ==="

# Update package index
apt-get update -y

# Install Docker and Nginx
apt-get install -y docker.io nginx

echo "Docker and Nginx installed"

# Start Docker
systemctl enable docker
systemctl start docker

# Add ubuntu user to Docker group
usermod -aG docker ubuntu

# Configure Nginx
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

# Test Nginx configuration
nginx -t

# Start Nginx
systemctl enable nginx
systemctl restart nginx

# Verify installation
echo "=== DOCKER VERSION ==="
docker --version

echo "=== NGINX VERSION ==="
nginx -v

echo "=== DOCKER STATUS ==="
systemctl is-active docker

echo "=== NGINX STATUS ==="
systemctl is-active nginx

echo "=== SSM STATUS ==="
systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent.service || true

echo "USER_DATA_COMPLETED" > /tmp/user-data-completed

echo "=== USER DATA FINISHED ==="
EOF

  tags = {
    Name = "react-devops-web"
  }
}

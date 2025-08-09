#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin git openssl
usermod -aG docker azureuser

# Generate a self-signed certificate for HTTPS
mkdir -p /etc/ssl/docker
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/docker/selfsigned.key \
  -out /etc/ssl/docker/selfsigned.crt \
  -subj "/CN=localhost"

HOSTNAME=$(hostname)

if [[ "$HOSTNAME" == *"frontend"* ]]; then
  # Pull and run the frontend container exposing HTTPS
  docker pull yourdockerhubuser/frontend-image:latest
  docker run -d --name frontend -p 80:80 -p 443:80 \
    -v /etc/ssl/docker:/etc/ssl/docker \
    -e SSL_CERT=/etc/ssl/docker/selfsigned.crt \
    -e SSL_KEY=/etc/ssl/docker/selfsigned.key \
    yourdockerhubuser/frontend-image:latest
elif [[ "$HOSTNAME" == *"backend"* ]]; then
  # Clone and run the backend application using Docker Compose
  git clone https://github.com/Appster-Capstone-Project/Capstone-Project-Backend.git /opt/backend
  cd /opt/backend || exit
  docker compose up -d
fi


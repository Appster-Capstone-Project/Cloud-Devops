#!/bin/bash
apt-get update
apt-get install -y docker.io git openssl
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
  # Pull and run the backend container exposing HTTPS
  docker pull yourdockerhubuser/backend-image:latest
  docker run -d --name backend -p 5000:5000 -p 443:5000 \
    -v /etc/ssl/docker:/etc/ssl/docker \
    -e SSL_CERT=/etc/ssl/docker/selfsigned.crt \
    -e SSL_KEY=/etc/ssl/docker/selfsigned.key \
    yourdockerhubuser/backend-image:latest
fi


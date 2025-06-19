#!/bin/bash
apt-get update
apt-get install -y docker.io git
usermod -aG docker azureuser

# Pull your frontend and backend images from Docker Hub (replace with your actual image names)
docker pull yourdockerhubuser/frontend-image:latest
docker pull yourdockerhubuser/backend-image:latest

# Run frontend (on port 80) and backend (on port 5000 or any other)
docker run -d --name frontend -p 80:80 yourdockerhubuser/frontend-image:latest
docker run -d --name backend -p 5000:5000 yourdockerhubuser/backend-image:latest

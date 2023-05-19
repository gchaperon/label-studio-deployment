#!/bin/bash
set -e

# Make apt-get install don't complain about not having a terminal connection
# See https://discuss.hashicorp.com/t/how-to-fix-debconf-unable-to-initialize-frontend-dialog-error/39201
# mikeschinkel never reported back :-(
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Install nginx
sudo apt-get update
sudo apt-get install -y nginx

# Install docker, see https://docs.docker.com/engine/install/debian/
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Move docker compose file to final destination, create necessary dirs
sudo mkdir /labelstudio /labelstudio/postgres-data /labelstudio/mydata
sudo chown 1001 /labelstudio/mydata
sudo mv /tmp/docker-compose.yaml /labelstudio
sudo chown root /labelstudio/docker-compose.yaml


# Configure nginx
sudo rm /etc/nginx/sites-enabled/*
sudo mv /tmp/labelstudio.conf /etc/nginx/conf.d
sudo sed -i -E "s/^server(.*)/server\1\n\tserver_name $CERTBOT_DOMAIN;/" /etc/nginx/conf.d/labelstudio.conf


# Pull docker images
sudo docker compose -f /labelstudio/docker-compose.yaml pull


# Install certbot, https://certbot.eff.org/instructions?ws=nginx&os=debianbuster
sudo apt-get install -y snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
# sudo certbot -n -d $CERBOT_DOMAIN --nginx --agree-tos --email $CERTBOT_EMAIL

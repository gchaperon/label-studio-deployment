#!/bin/bash
set -e

# Make apt-get install don't complain about not having a terminal connection
# See https://discuss.hashicorp.com/t/how-to-fix-debconf-unable-to-initialize-frontend-dialog-error/39201
# mikeschinkel never reported back :-(
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

# Configure systemd service
# Insert env vars right below [Service] block
sudo mv /tmp/labelstudio.service /etc/systemd/system
sudo sed -i -E "/^\[Service\]$/r /dev/stdin" /etc/systemd/system/labelstudio.service <<EOF
Environment=LABEL_STUDIO_USERNAME=$LABEL_STUDIO_USERNAME
Environment=LABEL_STUDIO_PASSWORD=$LABEL_STUDIO_PASSWORD
EOF
sudo systemctl enable labelstudio

# Prepare for docker install, see https://docs.docker.com/engine/install/ubuntu/
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Install docker, nginx, snapd
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
	docker-buildx-plugin docker-compose-plugin nginx snapd


# Install certbot, https://certbot.eff.org/instructions?ws=nginx&os=debianbuster
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
# TODO: Do this part in cloud-init, you cannot request a certificate when there is no A record
# pointing to this machine (this image will be deployed in a different machine)
# sudo certbot -n -d $CERTBOT_DOMAIN --nginx --agree-tos --email $CERTBOT_EMAIL


# Move docker compose file to final destination, create necessary dirs, pull docker images, initialize db
sudo mkdir /labelstudio /labelstudio/postgres-data /labelstudio/labelstudio-data
sudo chown 1001 /labelstudio/labelstudio-data
sudo mv /tmp/docker-compose.yaml /labelstudio
sudo chown root /labelstudio/docker-compose.yaml
sudo docker compose -f /labelstudio/docker-compose.yaml pull
sudo docker compose -f /labelstudio/docker-compose.yaml up -d
until curl -sIL localhost:8080/health > /dev/null
do
	sleep 1
	echo Waiting for labelstudio db migrations
done
echo Done
sudo docker compose -f /labelstudio/docker-compose.yaml down


# Configure nginx
sudo rm /etc/nginx/sites-enabled/*
sudo mv /tmp/labelstudio.conf /etc/nginx/conf.d
sudo sed -i -E "s/^server(.*)/server\1\n\tserver_name $CERTBOT_DOMAIN;/" /etc/nginx/conf.d/labelstudio.conf




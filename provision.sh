#!/bin/bash
set -e

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
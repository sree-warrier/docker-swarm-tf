#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce -y
sudo docker swarm init
sudo docker swarm join-token --quiet worker > /home/ubuntu/token
sudo chown ubuntu.ubuntu /home/ubuntu/token
sudo usermod -aG docker ubuntu
#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
#sleep 30
sudo apt-get install docker-ce -y
#sudo chmod 400 /home/ubuntu/sreekanth-key.pem
#sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i sreekanth-key.pem ubuntu@${aws_instance.master.private_ip}:/home/ubuntu/token .
#sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.master.private_ip}:2377
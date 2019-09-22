sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i key.pem ubuntu@$1:/home/ubuntu/token .
sudo docker swarm join --token $(cat /home/ubuntu/token) $1:2377

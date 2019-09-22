
scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -i key.pem /home/ubuntu/key.pem ubuntu@$2:/home/ubuntu/
ssh -i key.pem ubuntu@$2 "bash -s" < swarm-join.sh $1

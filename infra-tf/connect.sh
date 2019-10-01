
scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -i key-pair.pem /home/ubuntu/key-pair.pem ubuntu@$2:/home/ubuntu/
ssh -i key-pair.pem ubuntu@$2 "bash -s" < swarm-join.sh $1

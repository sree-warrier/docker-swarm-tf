scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -i sreekanth-key.pem /home/ubuntu/sreekanth-key.pem ubuntu@$2:/home/ubuntu/
ssh -i sreekanth-key.pem ubuntu@$2 "bash -s" < swarm-join.sh $1

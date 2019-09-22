# Terraform + Docker-Swarm setup

Deploy a docker-swarm environment in a VPC using Terraform

Includes
--------

* VPC
* Internal DNS
* EC2 instances
* ELB to distribute requests across the EC2 instances
* Security groups
* docker, docker swarm & docker-compose


Prerequisites
-------------

* Terraform should be installed. Get it from https://www.terraform.io/downloads.html to grab the latest version.
* An AWS account http://aws.amazon.com/

Usage
-----

Building the infra using terraform commands

The following steps will walk you through the process:

1. Clone the repo::

      git clone `https://github.com/sree-warrier/docker-swarm-tf.git`

2. Following should be created before terraform file execution::

    - Create a keypair or use an existing one
    - Update key pair under respective file main.tf, swarm-join.sh, connect.sh
    - Configure aws credentials, update the access and secret keys in variable.tf

3. infra-tf directory conatins the terraform file for infra setup, use the following steps::

      ```
      cd infra-tf
      terraform init
      terraform plan
      terraform apply
      ```

4. Once the infra is up, follow these steps for a slave to join the swarm.

    - Login to the Jump instance using the key
    - Get the swarm-master ip and swarm-slave ip
    - Execute this command
      ```bash connect.sh <swarm-master-ip> <swarm-slave-ip>```

## Credits
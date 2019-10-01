# Terraform + Docker-Swarm setup

Deploy a docker-swarm environment in a VPC using Terraform

Includes
--------

* VPC
* Internal DNS
* EC2 instances
* ALB
* Security groups
* IAM SSL
* route53
* docker, docker swarm
* Jenkins
* CI/CD


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
    - Update key pair under respective file main.tf, swarm-join.sh, connect.sh by changing the value "key-pair.pem".
    - Make sure that the key file should be copied under the infra-tf directory, were the terraform execution is processed
    - Configure aws credentials, update the access and secret keys in variable.tf
    - Updated your local public IP under the security group section in main.tf file 

3. infra-tf directory conatins the terraform file for infra setup, use the following steps::

      ```
      cd infra-tf
      terraform init
      terraform plan
      terraform apply
      ```

4. Once the infra is up, follow these steps for a slave to join the swarm.

    - Login to the Jump instance using the key 
    - Execute this command in Jump box

      ```bash connect.sh <swarm-master-ip/hostname> <swarm-slave-ip/hostname>```

      eg : ```bash connect.sh master.swarm-tf.com slave0.swarm-tf.com```

5. To increase the swarm-slave

    - Update the count value under the slave resource in main.tf file
    - Then follow the Step 4

6. Jenkins

    - Installed and configured the Jenkins box. Following are the steps taken for CI/CD workflow through jenkins.
    - Publish over ssh is the plugin used for this task, installed and updated the remote host with swarm master hostname as configured in terrform file.
    - Created Jobs for build
    - Build trigger configured with the Poll SCM with cron (*/2 * * * *).
    - Updated the git repo in the configs.
    - Build configs are updated with the docker hub registery details.
    - Post build configs are updated with the deployment commands which has to be executed in the swarm master box.

## Credits

provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
  version = "~> 1.58"
}

#######################
####VPC
#######################

#VPC definition with 6 subnet ranges
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "1.67.0"

  name = "swarm-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

#######################
####EC2-INSTANCE
#######################


#ec2 instance launch for swarm master
resource "aws_instance" "master" {
  count         = 1
  ami           = "ami-04613ff1fdcd2eab1"
  instance_type = "t2.micro"
  key_name = "key"
  subnet_id = "${element(module.vpc.private_subnets, 0)}"
  vpc_security_group_ids = ["${aws_security_group.swarm-sg.id}"]
  user_data = "${file("swarm-master.sh")}"
  tags = {
    Name = "swarm-master"
  }
}

#ec2 instance launch for swarm slave
resource "aws_instance" "slave" {
  count         = 2
  ami           = "ami-04613ff1fdcd2eab1"
  instance_type = "t2.micro"
  key_name = "key"
  subnet_id = "${element(module.vpc.private_subnets, 0)}"
  vpc_security_group_ids = ["${aws_security_group.swarm-sg.id}"]
  user_data = "${file("swarm-slave.sh")}"
  tags = {
    Name = "swarm-${count.index}"
  }
}
#ec2 instance launch for jump
resource "aws_instance" "jump" {
  count                  = 1
  ami                    = "ami-04613ff1fdcd2eab1"
  instance_type          = "t2.micro"
  key_name               = "key"
  associate_public_ip_address	= true
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id              = "${element(module.vpc.public_subnets, 0)}"

  provisioner "file" {
    source = "key.pem"
    destination = "/home/ubuntu/key.pem"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("key.pem")}"
  }
  }
  provisioner "file" {
    source = "connect.sh"
    destination = "/home/ubuntu/connect.sh"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("key.pem")}"
  }
  }
  provisioner "file" {
    source = "swarm-join.sh"
    destination = "/home/ubuntu/swarm-join.sh"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("key.pem")}"
  }
  }
  tags = {
    Name = "jump"
  }
}


#######################
####SECURITY GROUPS
#######################

#security-grp for apps slave connection via ssh
resource "aws_security_group" "swarm-sg" {
  name        = "swarm-sg"
  description = "Allow All access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.0.0/16"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#security-grp for jump connection via ssh
resource "aws_security_group" "allow_ssh" {
  name        = "jump-ssh"
  description = "Allow SSH access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["your local IP"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
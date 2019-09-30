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
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

#######################
####ALB
#######################

#app alb
resource "aws_lb" "front_end" {
  name               = "swarm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.https_alb.id}"]
  subnets            = ["${element(module.vpc.public_subnets, 0)}","${element(module.vpc.public_subnets, 1)}"]
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.front_end.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_iam_server_certificate.swarm-cert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}
resource "aws_lb_target_group" "front_end" {
  name     = "swarm-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"
}
resource "aws_lb_target_group_attachment" "front_end" {
  target_group_arn = "${aws_lb_target_group.front_end.arn}"
  target_id        = "${aws_instance.master.id}"
  port             = 80
}

###############
#static alb
resource "aws_lb" "static_front_end" {
  name               = "swarm-static-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.https_alb.id}"]
  subnets            = ["${element(module.vpc.public_subnets, 0)}","${element(module.vpc.public_subnets, 1)}"]
}
resource "aws_lb_listener" "static_front_end" {
  load_balancer_arn = "${aws_lb.static_front_end.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_iam_server_certificate.swarm-cert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.static_front_end.arn}"
  }
}
resource "aws_lb_target_group" "static_front_end" {
  name     = "swarm--static-tg"
  port     = 81
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"
}
resource "aws_lb_target_group_attachment" "static_front_end" {
  target_group_arn = "${aws_lb_target_group.static_front_end.arn}"
  target_id        = "${aws_instance.master.id}"
  port             = 81
}
#######################
####EC2-INSTANCE
#######################

#ec2 instance launch for swarm master
resource "aws_instance" "master" {
  count         = 1
  ami           = "ami-04613ff1fdcd2eab1"
  instance_type = "t2.micro"
  key_name = "sreekanth-key"
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
  key_name = "sreekanth-key"
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
  key_name               = "sreekanth-key"
  associate_public_ip_address	= true
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id              = "${element(module.vpc.public_subnets, 0)}"
  provisioner "file" {
    source = "sreekanth-key.pem"
    destination = "/home/ubuntu/sreekanth-key.pem"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("sreekanth-key.pem")}"
  }
  }
  provisioner "file" {
    source = "connect.sh"
    destination = "/home/ubuntu/connect.sh"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("sreekanth-key.pem")}"
  }
  }
  provisioner "file" {
    source = "swarm-join.sh"
    destination = "/home/ubuntu/swarm-join.sh"
    connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("sreekanth-key.pem")}"
  }
  }
  tags = {
    Name = "jump"
  }
}
#ec2 instance launch for jenkins
resource "aws_instance" "jenkins" {
  count         = 1
  ami           = "ami-0b002ca8dcaeca431"
  instance_type = "t2.micro"
  key_name = "sreekanth-key"
  subnet_id = "${element(module.vpc.public_subnets, 0)}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}","${aws_security_group.jenkins-sg.id}"]
  tags = {
    Name = "jenkins"
  }
}

#######################
####SSL certificate
#######################
resource "aws_iam_server_certificate" "swarm-cert" {
  name_prefix      = "swarm-cert"
  certificate_body = "${file("certificate.pem")}"
  private_key      = "${file("key.pem")}"
}

#######################
####Route 53
#######################
#private zone creation and vpc association
resource "aws_route53_zone" "private" {
  name = "swarm-tf.com"

  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }

}
resource "aws_route53_record" "master" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "master.swarm-tf.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.master.private_ip}"]
}
resource "aws_route53_record" "slave" {
  count = "${aws_instance.slave.count}"
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "slave${count.index}.swarm-tf.com"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.slave.*.private_ip, count.index)}"]
}
#######################
####SECURITY GROUPS
#######################
#security-grp for swarm-cluster
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

#security-grp for jenkins access
resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  description = "Allow UI Access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["182.74.184.211/32","182.75.87.26/32"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
#security-grp for public box connection via ssh
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
    cidr_blocks = ["182.74.184.211/32","182.75.87.26/32"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
#security-grp for alb
resource "aws_security_group" "https_alb" {
  name        = "https_alb"
  description = "Allow https access"
  vpc_id      = "${module.vpc.vpc_id}"
    ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["182.74.184.211/32","182.75.87.26/32"]
  }
    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
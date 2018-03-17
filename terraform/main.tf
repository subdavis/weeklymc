provider "aws" {
  region = "us-east-1"
}

##################################################################
# IAM Role + Instance Profile
##################################################################

resource "aws_iam_role" "role" {
  name               = "craft"
  assume_role_policy = "${file("assume-role-policy.json")}"
}

resource "aws_iam_policy" "policy" {
  name        = "craft"
  description = "A craft policy"
  policy      = "${file("policy-s3-bucket.json")}"
}

resource "aws_iam_policy_attachment" "craft-attach" {
  name       = "craft-attachment"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "craft_profile" {
  name  = "craft_profile"
  role = "${aws_iam_role.role.name}"
}

##################################################################
# Data sources to get VPC, subnet, security group and AMI details
##################################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*",
    ]
  }

  filter {
    name = "owner-id"

    values = [
      "099720109477",
    ]
  }
}

module "security_group" {
  source = "github.com/terraform-aws-modules/terraform-aws-security-group"

  name        = "craft"
  description = "Security group for usage with EC2 instance craft"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "http-8080-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 25565
      to_port     = 25565
      protocol    = "tcp"
      description = "craft"
      cidr_blocks = "0.0.0.0/0" 
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 1
      to_port     = 65535
      protocol    = "tcp"
      description = "egress all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

data "template_file" "init" {
  template = "${file("${path.module}/../user_data_thin.sh")}"
}

module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  name                        = "craft"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.medium"
  iam_instance_profile        = "${aws_iam_instance_profile.craft_profile.name}"
  subnet_id                   = "${element(data.aws_subnet_ids.all.ids, 0)}"
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  key_name                    = "weekly-minecraft"
  user_data                   = "${data.template_file.init.rendered}"
  associate_public_ip_address = true
}
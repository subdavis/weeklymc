provider "aws" {
  region = "eu-west-1"
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
  roles = ["${aws_iam_role.role.name}"]
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
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
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
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 25565
      to_port     = 25565
      description = "craft"
      cidr_blocks = "0.0.0.0/0" 
    }
  ]
}

module "ec2" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"

  name                        = "craft"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "m4.large"
  iam_instance_profile        = "${aws_iam_instance_profile.craft_profile.name}"
  subnet_id                   = "${element(data.aws_subnet_ids.all.ids, 0)}"
  vpc_security_group_ids      = ["${module.security_group.this_security_group_id}"]
  associate_public_ip_address = true
}
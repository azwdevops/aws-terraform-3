# configured aws provider with proper credentials using named profile to avoid exposing aws keys/secret
provider "aws" {
  region  = "us-east-2"
  profile = "your_named_profile_name"
}

# store the terraform state file in S3
terraform {
  backend "s3" {
    bucket  = "your_s3_bucket_name"
    key     = "build/terraform.tfstate" # the location where terraform will store the state file
    region  = "us-east-2"
    profile = "your_named_profile_name"
  }
}

# create default vpc

resource "aws_default_vpc" "my_default_vpc" {
  tags = {
    Name = "my_default_vpc"
  }
}


# use data source to get all availability zones in your region
data "aws_availability_zones" "availability_zones" {}

# create default subnet
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.availability_zones.names[0]

  tags = {
    Name = "my default subnet"
  }
}

# create security group for the ec2 instance

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2  security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.my_default_vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2 security group"
  }
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm"]
  }
}

# launch the ec2 instance and install website
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "myec2key"
  user_data              = file("install_website.sh")

  tags = {
    Name = "Website server"
  }
}

# print the url of the server
output "ec2_public_ipv4_url" {
  value = join("", ["http://", aws_instance.ec2_instance.public_ip])
}

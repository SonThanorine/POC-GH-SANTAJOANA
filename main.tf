terraform {

  backend "s3" {
    bucket = "goahead-terraform-tfsate"
    key    = "poc/vpc-santajoana/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {

  region = var.region
}
###################################################################################################
# VPC, SUBNETS, ROUTES, INTERNET-GATEWAY USADAS PARA OS SERVIÇOS POC GO-HEALTH SANTA JOANA
resource "aws_vpc" "GH-SANTAJOANA" {
    cidr_block       = "10.189.0.0/16"
    instance_tenancy = "default"

    tags = merge(

        local.gh_tags_poc,
        {
        Name = "VPC-GH-SANTAJOANA"
        }
    )
}
#-------------------------------------------------------------------------------------------------#
resource "aws_subnet" "PUB-1A" {
    vpc_id            = aws_vpc.GH-SANTAJOANA.id
    cidr_block        = "10.189.10.0/24"
    availability_zone = var.az-a
    map_public_ip_on_launch = true

    tags = merge(
        local.gh_tags_poc,
        {
            Name = "GH-SANTAJOANA-AZA-PUB"
        }
    )
}
#-------------------------------------------------------------------------------------------------#
resource "aws_internet_gateway" "GH-SANTAJOANA" {
  vpc_id = aws_vpc.GH-SANTAJOANA.id

  tags = merge(
      local.gh_tags_poc,
      {
          Name = "IGW-GH-SANTAJOANA"
      }
  )
}
#-------------------------------------------------------------------------------------------------#
resource "aws_route_table" "RTB-GH-SANTAJOANA" {
    vpc_id = aws_vpc.GH-SANTAJOANA.id

    tags = merge(
        local.gh_tags_poc,
        {
            Name = "RTB-GH-SANTAJOANA"
        }
    )
}

resource "aws_route" "DEFAULT-ROUTE" {
    route_table_id         = aws_route_table.RTB-GH-SANTAJOANA.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GH-SANTAJOANA.id
}

resource "aws_route_table_association" "ASS-PUB-1A" {
    subnet_id = aws_subnet.PUB-1A.id
    route_table_id = aws_route_table.RTB-GH-SANTAJOANA.id
}
#-------------------------------------------------------------------------------------------------#
resource "aws_security_group" "SG-GOHEALTH" {
    name        = "SG-GOHEALTH"
    description = "SG-GOHEALTH"
    vpc_id      = aws_vpc.GH-SANTAJOANA.id

    ingress {
        description = ""
        from_port   = 80
        to_port     = 80
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = ""
        from_port   = 3389
        to_port     = 3389
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = ""
        from_port   = 8889
        to_port     = 8889
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = ""
        from_port   = 0
        to_port     = 0
        protocol    = "all"
        cidr_blocks = ["0.0.0.0/0"]

    }

    tags = merge(
        local.gh_tags_poc,
        {
            Name = "SG-GH-SANTAJOANA"
        }
    )
}
#-------------------------------------------------------------------------------------------------#
resource "aws_instance" "GH-SERVER" {
  ami           = data.aws_ami.windows-2019.id
  instance_type = "m5.xlarge"
  availability_zone = "sa-east-1a"
  vpc_security_group_ids = [aws_security_group.SG-GOHEALTH.id]
  subnet_id = aws_subnet.PUB-1A.id
  hibernation = false
  
  ebs_block_device {
    device_name = "xvdb"
    volume_type = "gp2"
    volume_size = 500
    delete_on_termination = true
    encrypted = false

    tags = merge(
    local.gh_tags_poc,
        {
            Name = "GH-SANTAJOANA-SERVER-DISKDATA"
        }
    )
  }
  
  tags = merge(
    local.gh_tags_poc,
        {
            Name = "EC2-GH-SANTAJOANA-SERVER"
        }
    )
}

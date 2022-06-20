# Get Windows Server 2019 (2022.03.09) AMI
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-2022.03.09"]
  }
}
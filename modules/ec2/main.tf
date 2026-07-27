variable "name" {}
variable "ami_id" {}
variable "instance_type" { default = "t3.micro" }
variable "subnet_id" {}
variable "security_group_ids" { type = list(string) }
variable "instance_profile_name" {}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.instance_profile_name

  metadata_options { http_tokens = "required" }  # enforce IMDSv2

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  tags = { Name = var.name }
}

output "instance_id" { value = aws_instance.this.id }
output "private_ip" { value = aws_instance.this.private_ip }

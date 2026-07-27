terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket         = "ujjwal-tf-state-601226954823"
    key            = "aws-infra-automation/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "ap-south-1" }

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "dev-infra"
  azs                   = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs   = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs  = ["10.10.10.0/24", "10.10.11.0/24"]
}

module "iam" {
  source      = "../../modules/iam"
  name        = "dev-infra"
  policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
}

module "app_bucket" {
  source      = "../../modules/s3"
  bucket_name = "dev-infra-app-artifacts-601226954823"
}

module "web_server" {
  source                 = "../../modules/ec2"
  name                    = "dev-web"
  ami_id                  = "ami-08e8e63035c905918" # Amazon Linux 2023, ap-south-1 - verify current AMI before apply
  instance_type           = "t3.micro"
  subnet_id               = module.vpc.public_subnet_ids[0]
  security_group_ids      = [module.vpc.web_sg_id]
  instance_profile_name   = module.iam.instance_profile_name
}

resource "aws_sns_topic" "alerts" {
  name = "dev-infra-alerts"
}

module "cloudwatch_alarms" {
  source               = "../../modules/cloudwatch"
  instance_id          = module.web_server.instance_id
  alarm_sns_topic_arn  = aws_sns_topic.alerts.arn
}

output "vpc_id"       { value = module.vpc.vpc_id }
output "bucket_id"    { value = module.app_bucket.bucket_id }
output "web_ip"       { value = module.web_server.private_ip }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }# ci-debug-trigger
# ci-debug-trigger-3

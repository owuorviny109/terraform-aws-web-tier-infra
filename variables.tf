variable "region" {
  description = "AWS region to deploy resources to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources to"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
# variables.tf

variable "my_ip_cidr" {
  description = "Your IP address in CIDR format for SSH"
  type        = string
  default     = "41.89.x.x/32" # Replace with your real IP
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "terraform-key"  # Added default value
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Update if needed for your region
}

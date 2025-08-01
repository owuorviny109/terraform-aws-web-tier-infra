# Images Directory

This directory contains visual documentation for the Terraform AWS Web Tier Infrastructure project.

## Current Files

### Architecture Diagram
- `architecture-diagram.png` - Visual representation of the 3-tier AWS architecture showing:
  - VPC with 2 Availability Zones (AZ1 and AZ2)
  - Public subnet with Bastion Host and Web Server
  - Private subnets with App Server and RDS MariaDB
  - Internet Gateway and NAT Gateway
  - Route tables and security groups

### Web Application Screenshot
- `web-output.png` - Screenshot of the deployed web application showing:
  - Professional landing page with "Terraform Web Server Deployment" title
  - Custom styling with gradient background
  - Infrastructure details and deployment information
  - Author attribution and technology stack

### AWS Console Screenshots
- `aws-console-vpc.png` - AWS VPC Resource Map showing:
  - 4 subnets (1 public in us-east-1a, 3 private across us-east-1a and us-east-1b)
  - 3 route tables (public-route-table, private-route-table, default)
  - 2 network connections (main-igw, main-nat-gateway)
  - Complete network topology and resource relationships

### Additional Screenshots to Add
- `aws-console-ec2.png` - AWS EC2 console showing running instances
- `aws-console-rds.png` - AWS RDS console showing database instance
- `terraform-output.png` - Terminal screenshot showing Terraform outputs

## Usage in Documentation
These images are referenced in the main README.md and documentation files to provide visual context for the infrastructure deployment.

## Image Guidelines
- Use PNG format for screenshots
- Ensure sensitive information (IPs, account IDs) are redacted
- Keep images under 1MB for faster loading
- Use descriptive filenames
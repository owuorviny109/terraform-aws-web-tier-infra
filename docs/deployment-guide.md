# Deployment Guide

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- SSH key pair for EC2 access

### AWS Permissions Required
Your AWS credentials need the following permissions:
- EC2 full access
- VPC full access
- RDS full access
- IAM read access (for security groups)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/owuorviny109/terraform-aws-web-tier-infra.git
cd terraform-aws-web-tier-infra
```

### 2. Configure Variables
Edit `variables.tf` or create `terraform.tfvars`:

```hcl
# terraform.tfvars
region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
key_name = "your-key-pair-name"
ami_id = "ami-0c02fb55956c7d316"  # Amazon Linux 2
my_ip_cidr = "YOUR.IP.ADDRESS.HERE/32"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Deployment
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

## Post-Deployment Steps

### 1. Get Output Values
```bash
terraform output
```

This will show:
- Bastion Host public IP
- Web Server public IP
- App Server private IP
- RDS endpoint

### 2. Test Web Server
Open browser and navigate to the Web Server public IP:
```
http://<web_public_ip>
```

### 3. Access Private Resources via Bastion

#### Upload SSH Key to Bastion
```bash
# Copy your private key to bastion host
scp -i your-key.pem your-key.pem ec2-user@<bastion_public_ip>:/home/ec2-user/
```

#### SSH to Bastion
```bash
ssh -i your-key.pem ec2-user@<bastion_public_ip>
```

#### From Bastion, Access App Server
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@<app_private_ip>
```

#### Test Database Connection
From the app server:
```bash
mysql --user=root --password='Re:Start!9' --host=<rds_endpoint>
```

## Verification Checklist

- [ ] Web server accessible from internet
- [ ] Bastion host accessible via SSH
- [ ] App server accessible from bastion
- [ ] Database accessible from app server
- [ ] NAT Gateway providing internet access to private subnets
- [ ] Security groups properly configured

## Troubleshooting

### Common Issues

#### 1. SSH Connection Refused
- Verify security group allows SSH from your IP
- Check that key pair name matches in variables
- Ensure instance is in running state

#### 2. Web Server Not Accessible
- Check security group allows HTTP (port 80)
- Verify instance has public IP assigned
- Check user data script executed successfully

#### 3. Database Connection Failed
- Verify RDS instance is available
- Check security group allows MySQL (port 3306) from app server
- Confirm database credentials are correct

#### 4. Terraform Apply Fails
- Check AWS credentials are configured
- Verify region and availability zones are valid
- Ensure you have required permissions

### Useful Commands

#### Check Instance Status
```bash
aws ec2 describe-instances --region us-east-1
```

#### Check Security Groups
```bash
aws ec2 describe-security-groups --region us-east-1
```

#### Check RDS Status
```bash
aws rds describe-db-instances --region us-east-1
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

Type `yes` when prompted to confirm destruction.

**Warning**: This will permanently delete all resources and data.

## Cost Optimization

### Free Tier Resources Used
- t2.micro EC2 instances (750 hours/month free)
- db.t3.micro RDS instance (750 hours/month free)
- 20GB EBS storage (free)
- NAT Gateway (charges apply - ~$45/month)

### Cost Reduction Tips
- Use NAT Instance instead of NAT Gateway for development
- Stop instances when not in use
- Use smaller RDS instance classes
- Enable detailed monitoring only when needed

## Security Best Practices

1. **Rotate SSH Keys**: Regularly update EC2 key pairs
2. **Update AMIs**: Use latest Amazon Linux 2 AMI
3. **Patch Management**: Keep instances updated
4. **Database Security**: Change default passwords
5. **Network ACLs**: Add additional network-level security
6. **CloudTrail**: Enable for audit logging
7. **Backup Strategy**: Implement regular RDS snapshots
# Project Requirements

## Overview
This project implements a complete AWS 3-tier web architecture using Terraform Infrastructure as Code (IaC).

## VPC Setup Requirements

### Network Infrastructure
- **VPC**: Create main VPC with DNS support
- **Subnets**: 4 subnets total
  - 1 public subnet
  - 3 private subnets
- **High Availability**: Use 2 availability zones
  - Final private subnet can be in different AZ
- **Public IP**: Enable public IP addresses in subnet settings

### Networking Components
- **Elastic IP**: Allocate for NAT Gateway
- **NAT Gateway**: Create for private subnet internet access
- **Internet Gateway**: Create and attach to VPC
- **Route Tables**: 
  - Public route table with Internet Gateway
  - Private route table with NAT Gateway
  - Associate subnets to appropriate route tables

### Security Groups
Create security groups for:
- **Bastion Host**: SSH access
- **Web Server**: HTTP access
- **App Server**: Application tier access
- **Database**: Database tier access

**Important**: Link security groups together after creation (e.g., app server SG should reference database SG)

## EC2 Instance Requirements

### Bastion Host
- **Instance Type**: t2.micro
- **AMI**: Amazon Linux 2
- **Placement**: VPC public subnet
- **Security Group**: Bastion Host SG

### Web Server
- **Instance Type**: t2.micro
- **AMI**: Amazon Linux 2
- **Placement**: VPC public subnet
- **Security Group**: Web Server SG
- **User Data Script**:
  ```bash
  #!/bin/bash
  sudo yum update -y
  sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
  sudo yum install -y httpd
  sudo systemctl start httpd
  sudo systemctl enable httpd
  ```

### App Server
- **Instance Type**: t2.micro
- **AMI**: Amazon Linux 2
- **Placement**: VPC private subnet
- **Security Group**: App Server SG
- **User Data Script**:
  ```bash
  #!/bin/bash
  sudo yum install -y mariadb-server
  sudo service mariadb start
  ```

## Database Requirements

### RDS Setup
- **Create**: DB subnet group
- **Database Instance**:
  - Standard create
  - Engine: MariaDB
  - Tier: Free Tier
  - Automated backups: Disabled
  - Encryption: Disabled
  - Username: root
  - Password: Re:Start!9
  - Initial database: mydb

## Testing Requirements

### SSH Key Upload to Bastion
**Windows Users**:
```cmd
pscp -scp -P 22 -i '.\Downloads\labsuser.ppk' -l user ec2-user '.\Downloads\labsuser.pem' ec2-user@bastion-host-public-ip:/home/ec2-user
```

**Mac/Linux Users**:
```bash
chmod 400 labuser.pem
scp -i '.\Downloads\labsuser.pem' -l user ec2-user '.\Downloads\labsuser.pem' ec2-user@bastion-host-public-ip:/home/ec2-user
```

### Verification Steps
1. **SSH into Bastion Host**
2. **Verify key upload**: `ls` should show labsuser.pem
3. **Connect to App Server**:
   ```bash
   chmod 400 labsuser.pem
   ssh -i my-key-pair.pem ec2-user@app-server-private-ip
   ```
4. **Test connectivity**:
   - Ping web server: `ping web-server-private-ip`
   - Connect to database: `mysql --user=root --password='Re:Start!9' --host=database-server-endpoint`
   - Show databases: `show databases;`

## Success Criteria
- All infrastructure deployed via Terraform
- 3-tier architecture properly segmented
- Security groups configured with least privilege
- Database accessible only from app tier
- Web server accessible from internet
- Bastion host provides secure access to private resources
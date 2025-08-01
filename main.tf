########################
# VPC AND NETWORKING
########################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "private-subnet-c"
  }
}

########################
# ROUTING
########################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c_assoc" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

########################
# SECURITY GROUPS
########################

resource "aws_security_group" "bastion" {
  name        = "sg_bastion"
  description = "SSH access to bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["41.89.4.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name        = "sg_web"
  description = "HTTP access to web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name        = "sg_app"
  description = "Allow HTTP from web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name        = "sg_db"
  description = "Allow MySQL from app tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# EC2 INSTANCES
########################

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  associate_public_ip_address = true
  

  user_data = <<-EOF
  #!/bin/bash
  set -euxo pipefail

  # Update system and install Apache web server
  yum update -y
  yum install -y httpd

  # Disable default welcome page
  systemctl stop httpd
  rm -f /etc/httpd/conf.d/welcome.conf || true

  # Deploy a styled HTML landing page
  cat <<'EOT' > /var/www/html/index.html
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Deployment | Cloud Infrastructure Demo</title>
    <style>
      body {
        margin: 0;
        padding: 0;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background: linear-gradient(to right, #0f2027, #203a43, #2c5364);
        color: #ffffff;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        text-align: center;
      }

      header {
        padding: 2rem;
        background-color: rgba(255, 255, 255, 0.05);
        border-radius: 1rem;
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.3);
        max-width: 900px;
        margin: 2rem auto;
      }

      h1 {
        font-size: 3rem;
        margin-bottom: 1rem;
        color: #00d8ff;
      }

      h2 {
        font-size: 1.8rem;
        font-weight: 400;
        color: #ffffffb0;
      }

      p {
        font-size: 1.1rem;
        line-height: 1.6;
        margin-top: 1rem;
        color: #ffffffcc;
      }

      footer {
        margin-top: 2rem;
        font-size: 0.9rem;
        color: #cccccc;
      }

      .badge {
        display: inline-block;
        margin-top: 1rem;
        background: #1abc9c;
        color: #fff;
        padding: 0.4rem 1rem;
        border-radius: 2rem;
        font-size: 0.9rem;
      }

      @media (max-width: 600px) {
        h1 {
          font-size: 2rem;
        }
        p {
          font-size: 1rem;
        }
      }
    </style>
  </head>
  <body>
    <header>
      <h1>Terraform Web Server Deployment</h1>
      <h2>Automated Infrastructure Provisioned on AWS</h2>
      <p>
        This web server has been deployed using <strong>Infrastructure as Code (IaC)</strong> principles through Terraform,
        leveraging <strong>Amazon EC2</strong> and <strong>Apache HTTP Server</strong> in a cloud-native architecture. This demonstrates 
        automated provisioning, repeatable infrastructure, and rapid delivery at scale.
      </p>
      <p class="badge">Deployed via Terraform &mdash; by Vincent Omondi Owuor</p>
    </header>
    <footer>
      &copy; 2025 Cloud Engineering Demo &middot; AWS Certified | ALX SE Program | Terraform | EC2 | Apache
    </footer>
  </body>
  </html>
  EOT

  # Set ownership and permissions
  chown apache:apache /var/www/html/index.html
  chmod 644 /var/www/html/index.html

  # Start and enable Apache
  systemctl start httpd
  systemctl enable httpd
  EOF

  tags = {
    Name = "web-server"
  }
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    yum install -y mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
  EOF

  tags = {
    Name = "app-server"
  }
}

########################
# RDS INSTANCE (MariaDB)
########################

resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "mariadb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.6"
  instance_class       = "db.t3.micro"
  username             = "root"
  password             = "Re:Start!9"
  db_name              = "mydb"
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = false
  deletion_protection  = false
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name = "mydb"
  }
}

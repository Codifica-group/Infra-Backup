terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VARIÁVEIS

variable "key_name" {
  type = string
  default = "AWSKey"
}

variable "redis_password" {
  type = string
  description = "Senha (AUTH token) para o cluster Redis"
  sensitive = true
}

# REDE (VPC, Subnets, Gateways)

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "eleve-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/26"  
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.64/26"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name = "elasticache-subnet-group"
  subnet_ids = [aws_subnet.private.id]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-main"
  }
}

# IP Elástico para NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public.id
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gw-main"
  }
}

# TABELAS DE ROTA

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rt-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# GRUPOS DE SEGURANÇA (Firewall)

resource "aws_security_group" "web" {
  name = "web"
  description = "Webserver"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web"
  }
}

resource "aws_security_group" "app" {
  name = "app"
  description = "Appserver"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "App"  
    from_port = 8080
    to_port = 8081
    protocol = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description = "RabbitMQ AMQP (intra-app)"
    from_port = 5672
    to_port = 5672
    protocol = "tcp"
    self = true
  }
  ingress {
    description = "RabbitMQ Management (intra-app)"
    from_port = 15672
    to_port = 15672
    protocol = "tcp"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app"
  }
}

resource "aws_security_group" "db" {
  name = "db"
  description = "Databaseserver"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "MySQL"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db"
  }
}

resource "aws_security_group" "elasticache" {
  name = "elasticache"
  description = "Permitir conexoes do App Server ao ElastiCache"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Redis"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elasticache-sg"
  }
}

# INSTÂNCIAS EC2

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "web_server_1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = var.key_name

  tags = {
    Name = "web-server-01"  
  }
}

# IP ELÁSTICO WEBSERVER
resource "aws_eip" "web_public_ip" {
  domain = "vpc"

  tags = {
    Name = "eip-webserver-01"
  }
}

resource "aws_eip_association" "web_ip_assoc" {
  instance_id = aws_instance.web_server_1.id
  allocation_id = aws_eip.web_public_ip.id
}

resource "aws_instance" "app_server_1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name = var.key_name

  tags = {
    Name = "app-server-01"  
  }
}

resource "aws_instance" "app_server_2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name = var.key_name

  tags = {
    Name = "app-server-02"  
  }
}

resource "aws_instance" "chatbot_server_1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name = var.key_name

  tags = {
    Name = "chatbot-server"  
  }
}

resource "aws_instance" "db_server_1" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name = var.key_name

  tags = {
    Name = "db-server-01"  
  }
}

# Redis

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "eleve-redis-rg"
  description = "Cluster Redis para cache da aplicação Eleve"
  node_type = "cache.t3.micro"
  num_cache_clusters = 1
  automatic_failover_enabled = false
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]
  transit_encryption_enabled = true
  auth_token = var.redis_password
  engine_version = "7.0"
  parameter_group_name = "default.redis7"
  maintenance_window = "sun:05:00-sun:06:00"
}

output "elasticache_endpoint" {
  description = "Endpoint do Redis"
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

# GERA ARQUIVO DE INVENTARIO PARA ANSIBLE
resource "local_file" "ansible_inventory" {
  filename = "../inventory.ini"

  depends_on = [
    aws_elasticache_replication_group.main,
    aws_eip_association.web_ip_assoc,
  ]

  content = templatefile(
    "../inventory.ini.tpl",
    {
      web_public_ip = aws_eip.web_public_ip.public_ip
      eleve1_private_ip = aws_instance.app_server_1.private_ip
      eleve2_private_ip = aws_instance.app_server_2.private_ip
      chat1_private_ip = aws_instance.chatbot_server_1.private_ip
      db1_private_ip = aws_instance.db_server_1.private_ip
    }
  )
}

resource "local_file" "ansible_vars" {
  filename = "../vars.yml"

  depends_on = [
    aws_elasticache_replication_group.main,
  ]

  content = <<-EOT
    elasticache_endpoint: ${aws_elasticache_replication_group.main.primary_endpoint_address}
    EOT
}
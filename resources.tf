
provider "aws" {
  region = "eu-central-1"  # AWS region (Frankfurt)
  profile = "default"
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

}

# Create Public Subnet in eu-central-1a
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}

# Create Public Subnet in eu-central-1b
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1b"
  }
}

# Create Private Subnet in eu-central-1a
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "private-subnet-1a"
  }
}

# Create Private Subnet in eu-central-1b
resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "private-subnet-1b"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-internet-gateway"
  }
}

# Create a NAT Gateway in Public Subnet 1a
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "nat-gateway-1a"
  }
}

# Allocate an Elastic IP for NAT Gateway
resource "aws_eip" "nat_1a" {
  vpc = true
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Subnets with the Public Route Table
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate Private Subnets with the Private Route Table
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}

# Create EC2 Instance in Public Subnet 1a (SSH access)
resource "aws_instance" "admin_instance" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_1a.id
  key_name        = "ssh-access"  
  associate_public_ip_address = true

  tags = {
    Name = "admin-instance"
  }
  }
resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH access from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access"
  }
}




# Kubernetes Ingress
resource "kubernetes_ingress" "app_ingress" {
  metadata {
    name = "app-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"  # Assumes you have nginx ingress controller installed
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/app1"
          backend {
            service_name = kubernetes_service.app_service1.metadata[0].name
            service_port = 80
          }
        }

        path {
          path = "/app2"
          backend {
            service_name = kubernetes_service.app_service2.metadata[0].name
            service_port = 80
          }
        }

        path {
          path = "/app3"
          backend {
            service_name = kubernetes_service.app_service3.metadata[0].name
            service_port = 80
          }
        }
      }
    }
  }
}


# Kubernetes Services
resource "kubernetes_service" "app_service1" {
  metadata {
    name = "app-service1"
  }

  spec {
    selector = {
      app = "app1"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "app_service2" {
  metadata {
    name = "app-service2"
  }

  spec {
    selector = {
      app = "app2"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "app_service3" {
  metadata {
    name = "app-service3"
  }

  spec {
    selector = {
      app = "app3"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# Kubernetes Deployments
resource "kubernetes_deployment" "app_deployment1" {
  metadata {
    name = "app-deployment1"
    labels = {
      app = "app1"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "app1"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1"
        }
      }

      spec {
        container {
          name  = "app1-container"
          image = "nginx:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "app_deployment2" {
  metadata {
    name = "app-deployment2"
    labels = {
      app = "app2"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "app2"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2"
        }
      }

      spec {
        container {
          name  = "app2-container"
          image = "nginx:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "app_deployment3" {
  metadata {
    name = "app-deployment3"
    labels = {
      app = "app3"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "app3"
      }
    }

    template {
      metadata {
        labels = {
          app = "app3"
        }
      }

      spec {
        container {
          name  = "app3-container"
          image = "nginx:latest"

          port{
            container_port = 80
          }
        }
      }
    }
  }
}

# Horizontal Pod Autoscalers
resource "kubernetes_horizontal_pod_autoscaler" "hpa1" {
  metadata {
    name = "hpa1"
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.app_deployment1.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 3
    max_replicas = 10
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "hpa2" {
  metadata {
    name = "hpa2"
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.app_deployment2.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 3
    max_replicas = 10
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "hpa3" {
  metadata {
    name = "hpa3"
  }

  spec {
    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.app_deployment3.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 3
    max_replicas = 10
    target_cpu_utilization_percentage = 50
  }
}


# RDS Instance (Writer)
resource "aws_db_instance" "rds_writer" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  multi_az       = false
  publicly_accessible = false
  db_name        = "mydb"
  username       = "admin"
  password       = "password"
  tags = {
    Name = "rds-writer"
  }
}

# RDS Instance (Reader)
resource "aws_db_instance" "rds_reader" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  multi_az       = true
  publicly_accessible = false
  db_name        = "mydb"
  username       = "admin"
  password       = "password"
  tags = {
    Name = "rds-reader"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "my-rds-subnet-group"
  subnet_ids  = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  tags = {
    Name = "my-rds-subnet-group"
  }
}

# Create NATS Cluster (2 instances) in Private Subnets
resource "aws_instance" "nats_instance_1" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_1a.id
  associate_public_ip_address = false

  tags = {
    Name = "nats-instance-1"
  }
}

resource "aws_instance" "nats_instance_2" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_1b.id
  associate_public_ip_address = false

  tags = {
    Name = "nats-instance-2"
  }
}

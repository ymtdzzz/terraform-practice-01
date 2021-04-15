locals {
  database_name = "${local.ws}laravel"
  private_subnet_host = "${cidrhost(var.vpc_cidr, 0)}/${cidrnetmask(var.vpc_cidr)}"
}

resource "aws_security_group" "this" {
  name        = "${var.app_name}_${local.ws}"
  description = "${var.app_name}_${local.ws}"

  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${local.ws}"
  }
}

resource "aws_security_group_rule" "mysql" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.app_name}_${local.ws}"
  description = "${var.app_name}_${local.ws}"
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id,
    aws_subnet.private_1d.id
  ]
}

resource "random_password" "password" {
  length  = 16
  special = false
}

/* !!TODO!! */
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.app_name}-${local.ws}"

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  engine = "aurora-mysql"
  port   = 3306

  database_name   = local.database_name
  master_username = var.master_username
  master_password = random_password.password.result

  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = "${var.app_name}-${local.ws}"
  cluster_identifier = aws_rds_cluster.this.id

  engine = "aurora-mysql"

  instance_class = "db.t3.small"
}

# In production, app user should be created

# resource "random_password" "password_laravel" {
#   length  = 16
#   special = false
# }

# provider "mysql" {
#   endpoint = aws_rds_cluster.this.endpoint
#   username = var.master_username
#   password = random_password.password.result
# }

# # create laravel user
# resource "mysql_user" "laravel" {
#   user = var.laravel_username
#   host = local.private_subnet_host
#   plaintext_password = random_password.password_laravel.result
# }

# resource "mysql_grant" "laravel" {
#   user = mysql_user.laravel.user
#   host = local.private_subnet_host
#   database = local.database_name
#   privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"]
# }
/**/
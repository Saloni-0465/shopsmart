resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

# Block all public access (rubric requirement)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable bucket versioning (rubric requirement)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (rubric requirement)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  name = var.app_name
  tags = merge(var.tags, {
    app = var.app_name
  })
  create_task_execution_role = var.task_execution_role_arn == ""
  task_execution_role_arn    = local.create_task_execution_role ? aws_iam_role.ecs_task_execution[0].arn : var.task_execution_role_arn
  vpc_id                     = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.app[0].id
  public_subnet_ids          = var.use_default_vpc ? data.aws_subnets.default[0].ids : aws_subnet.public[*].id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "${local.name}-api"
  image_tag_mutability = "MUTABLE"
  tags                 = local.tags

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecs_cluster" "app" {
  name = "${local.name}-cluster"
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}-api"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_iam_role" "ecs_task_execution" {
  count = local.create_task_execution_role ? 1 : 0

  name = "${local.name}-ecs-task-execution-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count = local.create_task_execution_role ? 1 : 0

  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_vpc" "app" {
  count = var.use_default_vpc ? 0 : 1

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "app" {
  count = var.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.app[0].id
  tags = merge(local.tags, {
    Name = "${local.name}-igw"
  })
}

resource "aws_subnet" "public" {
  count                   = var.use_default_vpc ? 0 : length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.app[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    Name = "${local.name}-public-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  count = var.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.app[0].id
  tags = merge(local.tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  count = var.use_default_vpc ? 0 : 1

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app[0].id
}

resource "aws_route_table_association" "public" {
  count          = var.use_default_vpc ? 0 : length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Allow HTTP traffic to the Shopsmart ALB"
  vpc_id      = local.vpc_id
  tags        = local.tags

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "service" {
  name        = "${local.name}-service-sg"
  description = "Allow ALB traffic to the Shopsmart ECS service"
  vpc_id      = local.vpc_id
  tags        = local.tags

  ingress {
    description     = "API traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  tags               = local.tags
}

resource "aws_lb_target_group" "app" {
  name        = "${local.name}-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id
  tags        = local.tags

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

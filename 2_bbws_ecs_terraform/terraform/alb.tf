# ALB Module for POC1 - ECS Fargate Multi-Tenant WordPress

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Environment-specific setting (configured via tfvars)
  enable_deletion_protection = var.alb_deletion_protection
  enable_http2               = true

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

# Target Group for Tenant 1
resource "aws_lb_target_group" "tenant_1" {
  name        = "${var.environment}-tenant-1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate with awsvpc network mode

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-tenant-1-tg"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}

# ALB Listener (HTTP for POC)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "BBWS POC1 - Please use /tenant-{id}/ path"
      status_code  = "200"
    }
  }

  tags = {
    Name        = "${var.environment}-http-listener"
    Environment = var.environment
  }
}

# Listener Rule for Tenant 1 - Host-based routing with wpdev.kimmyai.io
resource "aws_lb_listener_rule" "tenant_1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant_1.arn
  }

  condition {
    host_header {
      values = ["tenant1.wpdev.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-tenant-1-rule"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}

# Default rule for backward compatibility (catch-all)
resource "aws_lb_listener_rule" "tenant_1_default" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant_1.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Name        = "${var.environment}-tenant-1-default-rule"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}

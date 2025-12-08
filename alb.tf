# --- 1. Automated Self-Signed Certificate ---
# This generates a private key in memory (not saved to disk)
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# This creates a self-signed cert valid for 1 year
resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "quest.local"
    organization = "Quest Organization"
  }

  validity_period_hours = 8760 # 1 Year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Import the cert into AWS ACM so the Load Balancer can use it
resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}

# --- 2. Application Load Balancer ---
resource "aws_lb" "main" {
  name               = "quest-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

# --- 3. Target Group ---
# Where the traffic goes (to the container on port 3000)
resource "aws_lb_target_group" "app_tg" {
  name        = "quest-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate

  health_check {
    path = "/" # The app has an index page
  }
}

# --- 4. Listeners ---
# Redirects all traffic to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (Port 443) - Uses our generated Cert
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- Outputs ---
# This prints the URL you need to click at the end!
output "alb_dns_name" {
  value = aws_lb.main.dns_name
  description = "The URL of the load balancer"
}
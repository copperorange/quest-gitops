# --- 1. IAM Roles (Permissions) ---
# This role allows Fargate to pull images from ECR and send logs to CloudWatch
resource "aws_iam_role" "ecs_execution_role" {
  name = "quest-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach the standard AWS policy for ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 2. Logs ---
# A place to store the app logs so you can debug if it crashes
resource "aws_cloudwatch_log_group" "quest_logs" {
  name              = "/ecs/quest-app"
  retention_in_days = 7
}

# --- 3. ECS Cluster ---
# The logical grouping for your services
resource "aws_ecs_cluster" "main" {
  name = "quest-cluster"
}

# --- 4. Task Definition (The Blueprint) ---
resource "aws_ecs_task_definition" "app" {
  family                   = "quest-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # .25 vCPU
  memory                   = 512 # 512 MB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "quest-app-container"
    # Using the repository URL from the ECR resource we imported/created
    image = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true

    # Port Mapping: App listens on 3000
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    # Environment Variables (The Secret Word Injection!)
    environment = [
      {
        name  = "SECRET_WORD"
        value = var.secret_word
      }
    ]

    # Logging config
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.quest_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# --- 5. ECS Service (The Runner) ---
resource "aws_ecs_service" "app" {
  name            = "quest-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count = var.app_count

  # Network Configuration
  network_configuration {
    # Referencing the subnets created in network.tf (assumed names)
    subnets          = aws_subnet.public[*].id 
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # Required because we are in public subnets
  }

  # Load Balancer Connection
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "quest-app-container"
    container_port   = 3000
  }

  # Ensure the ALB is ready before creating the service to avoid race conditions
  depends_on = [aws_lb_listener.https, aws_iam_role_policy_attachment.ecs_execution_policy]
}
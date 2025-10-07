# Cria o repositório ECR para a imagem da users-api
resource "aws_ecr_repository" "users_api" {
  name = "${var.project_name}/users-api"
}

# Cria o Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = var.project_name
}

# Cria o Log Group no CloudWatch para o container
resource "aws_cloudwatch_log_group" "users_api" {
  name = "/ecs/${var.project_name}/users-api"
}

# Cria a IAM Role que a tarefa ECS usará para puxar a imagem e enviar logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Define a Task Definition (planta do container)
resource "aws_ecs_task_definition" "users_api" {
  family                   = "${var.project_name}-users-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "users-api",
      image     = "${aws_ecr_repository.users_api.repository_url}:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 9001,
          hostPort      = 9001
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.users_api.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-users-api-task"
  }
}

# Cria o Serviço ECS (executa e gerencia as tarefas)
resource "aws_ecs_service" "users_api" {
  name            = "${var.project_name}-users-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.users_api.arn
  desired_count   = 1 # Inicia com 1 container rodando
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.users_api.arn
    container_name   = "users-api"
    container_port   = 9001
  }

  # Garante que o ALB e o Listener estejam prontos antes de criar o serviço
  depends_on = [aws_lb_listener.http]
}

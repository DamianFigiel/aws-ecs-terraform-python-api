##################################################################################
# ECS & ECR
##################################################################################

resource "aws_ecr_repository" "ecr_repository" {
  name = var.project
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-${var.cluster_name}"
  })
}

resource "aws_ecs_service" "ecs_service" {
  name    = "${var.project}-svc"
  cluster = aws_ecs_cluster.ecs_cluster.arn
  load_balancer {
    target_group_arn = aws_lb_target_group.elb_target_group_80.arn
    container_name   = var.project
    container_port   = 8080
  }
  desired_count                      = 1
  launch_type                        = "EC2"
  task_definition                    = aws_ecs_task_definition.ecs_task_definition.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  iam_role                           = aws_iam_service_linked_role.ecs_service_role.arn
  health_check_grace_period_seconds  = 0
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-svc"
  })
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  container_definitions = jsonencode([
    {
      name   = "${var.project}"
      image  = "${aws_ecr_repository.ecr_repository.repository_url}:latest"
      cpu    = 0
      memory = 768
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-task"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command  = ["CMD-SHELL", "curl http://localhost:8080/books || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
      }
    }
  ])
  family             = "${var.project}-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "bridge"
  requires_compatibilities = [
    "EC2"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-task-def"
  })
}

resource aws_service_discovery_http_namespace service_discovery_http_namespace {
  name = var.cluster_name
}
##################################################################################
# EC2 INSTANCES
##################################################################################

resource "aws_instance" "ec2_instance" {
  count                  = var.instance_count
  ami                    = data.aws_ami.aws_linux.id
  instance_type          = var.instance_type
  tenancy                = "default"
  subnet_id              = module.app.public_subnets[(count.index % var.vpc_public_subnet_count)]
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  source_dest_check      = true
  root_block_device {
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }
  user_data = <<EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
    echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
    EOF

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-inst-${count.index + 1}"
    ECS-Cluster = "${var.cluster_name}"
  })
}

resource "aws_lb" "elastic_load_balancer" {
  name               = "${var.project}-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.app.public_subnets[*]
  security_groups    = [aws_security_group.security_group_load_balancer.id]
  ip_address_type    = "ipv4"
  access_logs {
    enabled = false
    bucket  = ""
    prefix  = ""
  }
  enable_http2                     = "true"
  enable_cross_zone_load_balancing = "true"

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-lb"
  })
}

resource "aws_lb_listener" "elastic_load_balancer_listener_80" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.elb_target_group_80.arn
    type             = "forward"
  }

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-list-80"
  })
}

resource "aws_lb_listener" "elastic_load_balancer_listener_8080" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.elb_target_group_8080.arn
    type             = "forward"
  }

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-list-8080"
  })
}

resource "aws_security_group" "ec2_security_group" {
  description = "Security Group for ${var.project} Instance"
  name        = "${var.project}-inst-sg"
  vpc_id = module.app.vpc_id

  ingress {
    security_groups = [aws_security_group.security_group_load_balancer.id]
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
  }
  ingress {
    security_groups = [aws_security_group.security_group_load_balancer.id]
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-inst-sg"
  })
}

resource "aws_security_group" "security_group_load_balancer" {
  description = "Security Group foe ${var.project} Load Balancer"
  name        = "${var.project}-lb-sg"
  vpc_id = module.app.vpc_id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8080
    protocol  = "tcp"
    to_port   = 8080
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-lb-sg"
  })
}

resource "aws_lb_target_group" "elb_target_group_80" {
  health_check {
    interval            = 30
    path                = "/books"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
    matcher             = "200"
  }
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = module.app.vpc_id
  name   = "target-group-80"

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-tg-80"
  })
}

resource "aws_lb_target_group" "elb_target_group_8080" {
  health_check {
    interval            = 30
    path                = "/books"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
    matcher             = "200"
  }
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.app.vpc_id
  name        = "target-group-8080"

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-tg-8080"
  })
}
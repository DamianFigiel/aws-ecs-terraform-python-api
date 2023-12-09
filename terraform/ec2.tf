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
  # metadata_options {
  #   http_endpoint               = "enabled"
  #   http_put_response_hop_limit = 2
  #   instance_metadata_tags = "enabled"
  # }
  tags = {
    Name          = "${var.project}-inst-${count.index + 1}"
    "ecs:cluster" = "${var.cluster_name}"
  }
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
}

resource "aws_lb_listener" "elastic_load_balancer_listener_80" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.elb_target_group_80.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "elastic_load_balancer_listener_8080" {
  load_balancer_arn = aws_lb.elastic_load_balancer.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.elb_target_group_8080.arn
    type             = "forward"
  }
}

resource "aws_security_group" "ec2_security_group" {
  description = "Security Group for ${var.project} Instance"
  name        = "${var.project}-inst-sg"
  tags = {
    Name = "${var.project}-inst-sg"
  }
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
}

resource "aws_security_group" "security_group_load_balancer" {
  description = "Security Group foe ${var.project} Load Balancer"
  name        = "${var.project}-lb-sg"
  tags = {
    Name = "${var.project}-lb-sg"
  }
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
}


# resource "aws_network_interface" "EC2NetworkInterface" {
#     description = "ELB app/${var.project}-lb/cc2fbd847231a9d6"
#     private_ips = [
#         "172.31.15.36"
#     ]
#     subnet_id = "subnet-0bfb30b8cf2d2523a"
#     source_dest_check = true
#     security_groups = [
#         "${aws_security_group.EC2SecurityGroup2.id}"
#     ]
# }

# resource "aws_network_interface" "EC2NetworkInterface2" {
#     description = ""
#     private_ips = [
#         "172.31.5.116"
#     ]
#     subnet_id = "subnet-0bfb30b8cf2d2523a"
#     source_dest_check = true
#     security_groups = [
#         "${aws_security_group.EC2SecurityGroup.id}"
#     ]
# }

# resource "aws_network_interface" "EC2NetworkInterface3" {
#     description = ""
#     private_ips = [
#         "172.31.28.15"
#     ]
#     subnet_id = "subnet-0da0dceeb9d6b442e"
#     source_dest_check = true
#     security_groups = [
#         "${aws_security_group.EC2SecurityGroup.id}"
#     ]
# }

# resource "aws_network_interface" "EC2NetworkInterface4" {
#     description = "ELB app/${var.project}-lb/cc2fbd847231a9d6"
#     private_ips = [
#         "172.31.20.143"
#     ]
#     subnet_id = "subnet-0da0dceeb9d6b442e"
#     source_dest_check = true
#     security_groups = [
#         "${aws_security_group.EC2SecurityGroup2.id}"
#     ]
# }

# resource "aws_network_interface_attachment" "EC2NetworkInterfaceAttachment" {
#     network_interface_id = "eni-020b58f237f37b6f1"
#     device_index = 0
#     instance_id = "i-0f25a84c12cb4f24a"
# }

# resource "aws_network_interface_attachment" "EC2NetworkInterfaceAttachment2" {
#     network_interface_id = "eni-0216581e6c9323004"
#     device_index = 0
#     instance_id = "i-0f3d8e6019c2fee2a"
# }



# resource "aws_lb_target_group_attachment" "nginx1" {
#   target_group_arn = aws_lb_target_group.nginx.arn
#   target_id        = aws_instance.nginx1.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "nginx2" {
#   target_group_arn = aws_lb_target_group.nginx.arn
#   target_id        = aws_instance.nginx2.id
#   port             = 80
# }
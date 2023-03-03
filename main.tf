locals {
    http_port = 80
}

#************************************************************|
# Launch Configuration                                       |
#************************************************************|
resource "aws_launch_configuration" "asg_lc" {
  name_prefix   = "${var.cluster_name}-lc-"
  image_id      = "ami-0bb935e4614c12d86"
  instance_type = "t3.micro"
  spot_price = "0.0108"
  security_groups = [aws_security_group.asg_sg.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_text = var.server_text,
    server_port = var.server_port,
    db_address = var.db_address,
    db_port = var.db_port
  })

    lifecycle {
        create_before_destroy = true
    }
}

#************************************************************|
# Autoscaling Group Security Group                           | 
#************************************************************|
resource "aws_security_group" "asg_sg" {
    name = "${var.cluster_name}-tg-sg"
    description = "Allow HTTP traffic from load balancer"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "asg_sg_rule_ingress" {
    type = "ingress"
    description = "Allow traffic only from load balancer"
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    source_security_group_id = aws_security_group.asg_lb_sg.id
    security_group_id = aws_security_group.asg_sg.id
}

resource "aws_security_group_rule" "asg_sg_rule_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.asg_sg.id
}

#************************************************************|
# Autoscaling Group                                          | 
#************************************************************|
resource "aws_autoscaling_group" "asg" {
  name_prefix = "${var.cluster_name}-asg-"
  min_size = 2
  max_size = 5
  desired_capacity = 2
  launch_configuration = aws_launch_configuration.asg_lc.name
  vpc_zone_identifier = var.asg_subnets
  target_group_arns = [aws_lb_target_group.asg_tg.arn]
  health_check_type = "ELB"
  health_check_grace_period = 300 

    instance_refresh {
        strategy = "Rolling"
        preferences {
            min_healthy_percentage = 50
        }
    }

    tag {
        key = "Name"
        value = "asg-${var.cluster_name}"
        propagate_at_launch = true
    }

    dynamic "tag" {
        for_each = var.custom_tags

        content {
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
}

#************************************************************|
# Application Load Balancer                                  |
#************************************************************|
resource "aws_lb" "asg_lb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.asg_lb_sg.id]
  subnets            = var.alb_subnets
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.asg_lb.arn
    port              = local.http_port
    protocol          = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "Hello, World"
            status_code  = "200"
        }
    }
}

resource "aws_lb_listener_rule" "asg_lb_listener_rule" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.asg_tg.arn
    }

    condition {
        path_pattern {
            values = ["*"]
        }
    }
}

#************************************************************|
# Application Load Balancer Security Group                   |
#************************************************************|
resource "aws_security_group" "asg_lb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_http_to_alb" {
    type              = "ingress"
    security_group_id = aws_security_group.asg_lb_sg.id
    from_port         = local.http_port
    to_port           = local.http_port
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
    type              = "egress"
    security_group_id = aws_security_group.asg_lb_sg.id
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
}

#************************************************************|
# Application Load Balancer Target Group                     |
#************************************************************|
resource "aws_lb_target_group" "asg_tg" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

    health_check {
        path = "/"
        port = var.server_port
        protocol = "HTTP"
        matcher = "200"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.scale_in_at_night ? 1 : 0
    scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
    autoscaling_group_name = aws_autoscaling_group.asg.name
    desired_capacity = 0
    recurrence = "0 19 * * *"
    min_size = 0
    max_size = 2
}


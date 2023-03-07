locals {
    http_port = 80
    https_port = 443
}

###############################################################
# Launch Template                                             #
###############################################################
resource "aws_launch_template" "asg_lt" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = "ami-0bb935e4614c12d86"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
      max_price = "0.0108"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_text = var.server_text,
    server_port = var.server_port
  }))

    lifecycle {
        create_before_destroy = true
    }
}


#************************************************************#
# Launch Configuration                                       #
#************************************************************#
resource "aws_launch_configuration" "asg_lc" {
  name_prefix   = "${var.cluster_name}-lc-"
  image_id      = "ami-0bb935e4614c12d86"
  instance_type = "t3.micro"
  spot_price = "0.0108"
  security_groups = [aws_security_group.asg_sg.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_text = var.server_text,
    server_port = var.server_port
  })

    lifecycle {
        create_before_destroy = true
    }
}

#************************************************************#
# Autoscaling Group Security Group                           # 
#************************************************************#
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
    source_security_group_id = var.alb_sg_id
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

#************************************************************#
# Autoscaling Group                                          # 
#************************************************************#
resource "aws_autoscaling_group" "asg" {
  name_prefix = "${var.cluster_name}-asg-"
  min_size = 2
  max_size = 5
  desired_capacity = 2
  #launch_configuration = aws_launch_configuration.asg_lc.name
  vpc_zone_identifier = var.asg_subnets
  target_group_arns = [var.target_group_arn]
  health_check_type = "ELB"
  health_check_grace_period = 300 

    launch_template {
        id = aws_launch_template.asg_lt.id
        version = aws_launch_template.asg_lt.latest_version
    }

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

#************************************************************#
# Auto Scaling Group Schedules                               #
#************************************************************#
resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.scale_in_at_night ? 1 : 0
    scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
    autoscaling_group_name = aws_autoscaling_group.asg.name
    desired_capacity = 0
    recurrence = "0 19 * * *"
    min_size = 0
    max_size = 2
}

#************************************************************#
# RDS Security Group                                         # 
#************************************************************#
resource "aws_security_group" "rds_sg" {
    name = "${var.cluster_name}-rds-sg"
    description = "Allow traffic only from ASG EC2 instances"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "rds_sg_rule_ingress" {
    type = "ingress"
    description = "Allow traffic only from ASG EC2 instances"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = aws_security_group.asg_sg.id
    security_group_id = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_sg_rule_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.rds_sg.id
}
variable "server_port" {
    description = "The port the web server will listen on"
    type = number
    default = 80
}

variable "cluster_name" {
    description = "Name of the cluster"
    type        = string
}

variable "custom_tags" {
    description = "Custom tags to be added to resources"
    type = map(string)
    default = {}
}

variable "server_text" {
    description = "The text to be displayed on the web server"
    type = string
    default = "Hello, World!"
}

variable "asg_subnets" {
    description = "The subnets to deploy the ASG into"
    type = list(string)
}

variable "vpc_id" {
    description = "The VPC to deploy the resources into"
    type = string
}

variable "scale_in_at_night" {
    description = "Whether to scale in the ASG at night"
    type = bool
    default = true
}

variable "alb_sg_id" {
    description = "The security group ID of the ALB"
    type = string
}

variable "target_group_arn" {
    description = "The ARN of the target group"
    type = string
}

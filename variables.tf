variable "server_port" {
    description = "The port the web server will listen on"
    type = number
    default = 80
}

variable "db_address" {
    description = "The address of the database"
    type = string
}

variable "db_port" {
    description = "The port of the database"
    type = number
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

variable "alb_subnets" {
    description = "The subnets to deploy the ALB into"
    type = list(string)
}

variable "vpc_id" {
    description = "The VPC to deploy the resources into"
    type = string
}
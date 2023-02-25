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

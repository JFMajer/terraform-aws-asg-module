output "load_balancer_dns" {
  value = aws_lb.asg_lb.dns_name
  description = "DNS name of the load balancer"
}

output http_url {
  value = "http://${aws_lb.asg_lb.dns_name}"
}

output https_url {
  value = "https://${aws_lb.asg_lb.dns_name}"
}

output "alb_zone_id" {
  value = aws_lb.asg_lb.zone_id
  description = "Zone ID of the load balancer"
}

output "asg_security_group_id" {
  value = aws_security_group.asg_sg.id
  description = "Security group ID of the ASG"
}
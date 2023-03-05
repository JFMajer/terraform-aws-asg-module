
output "asg_security_group_id" {
  value = aws_security_group.asg_sg.id
  description = "Security group ID of the ASG"
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
  description = "Security group ID of the RDS"
}
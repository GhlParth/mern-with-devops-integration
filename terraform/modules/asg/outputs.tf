output "frontend_asg_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}

output "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group"
  value       = aws_autoscaling_group.backend.name
}

output "frontend_launch_template_id" {
  description = "ID of the frontend launch template"
  value       = aws_launch_template.frontend.id
}

output "backend_launch_template_id" {
  description = "ID of the backend launch template"
  value       = aws_launch_template.backend.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "app_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.app_server.public_ip}:5000"
}

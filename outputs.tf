output "alb_dns_name" {
  description = "A URL publica do Application Load Balancer."
  value       = aws_lb.main.dns_name
}

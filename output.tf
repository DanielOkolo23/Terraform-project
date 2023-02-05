output "Application_LB_DNS" {
  value = aws_lb.load-balancer.dns_name
}

output "target-group-arn"{
  value = aws_lb_target_group.target-group.arn
}

output "zone_id"{
  value = aws_lb.load-balancer.zone_id
}

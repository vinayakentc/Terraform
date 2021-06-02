




output "alb_dns_name2" {
  value = "${aws_lb.aws-alb2.dns_name}"
}

output "alb_target_group_arn2" {
  value = "${aws_lb_target_group.target-group2.arn}"
}









output "alb_dns_name1" {
  value = "${aws_lb.aws-alb1.dns_name}"
}



output "alb_target_group_arn1" {
  value = "${aws_lb_target_group.target-group1.arn}"
}





resource "aws_launch_configuration" "test-launch-config2" {
  image_id        = "ami-06b010d7ccc078d18"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.asg-sg2.id}"]
}

resource "aws_autoscaling_group" "Backend" {
  launch_configuration = "${aws_launch_configuration.test-launch-config2.name}"
  vpc_zone_identifier  = ["${var.subnet3}","${var.subnet4 }"]
  target_group_arns    = ["${var.target_group_arn2}"]
  health_check_type    = "EC2"
  
  min_size = 1
  max_size = 5

  tag {
    key                 = "Name"
    value               = "test-asg-backend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_policy_up2" {
	name = "web_policy_up2"
	scaling_adjustment = 1
	adjustment_type = "ChangeInCapacity"
	cooldown = 600
	autoscaling_group_name = "${aws_autoscaling_group.Backend.name}"
}

resource "aws_autoscaling_policy" "web_policy_down2" {
	name = "web_policy_down2"
	scaling_adjustment = -1
	adjustment_type = "ChangeInCapacity"
	cooldown = 600
	autoscaling_group_name = "${aws_autoscaling_group.Backend.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarmdown2"{
	alarm_name = "web_cpu_alarm_down2"
  statistic = "Average"
	comparison_operator = "LessThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	threshold = "20"

  dimensions = {
	  AutoScalingGroupName = "${aws_autoscaling_group.Backend.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web_policy_down2.arn}"]
}


resource "aws_security_group" "asg-sg2" {
  name   = "asg-sg2"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "asg_inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_database" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_backend" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.asg-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_lb_target_group" "target-group2" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "test-tg-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb" "aws-alb2" {
  name     = "test-alb2"
  internal = true

  security_groups = [
    "${aws_security_group.alb-sg2.id}",
  ]

  subnets = [
    "${var.subnet3}",
    "${var.subnet4}",
  ]

  tags = {
    Name = "test-alb-private"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "test-alb-listner3" {
   load_balancer_arn = "${aws_lb.aws-alb2.arn}"
   port              = 80
   protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = "${aws_lb_target_group.target-group2.arn}"
   }
}
resource "aws_lb_listener" "test-alb-listner2" {
   load_balancer_arn = "${aws_lb.aws-alb2.arn}"
   port              = 8000
   protocol          = "HTTP"

   default_action {
     type             = "forward"
     target_group_arn = "${aws_lb_target_group.target-group2.arn}"
   }
}

resource "aws_security_group" "alb-sg2" {
  name   = "alb-sg2"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_database" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "inbound_backend" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.alb-sg2.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


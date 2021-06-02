
resource "aws_launch_configuration" "test-launch-config" {
  image_id        = "ami-0f2f14c6fe94e3f32"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.asg-sg1.id}"]
  user_data           = <<-EOF
        #!/bin/bash
        
        cd  /etc/nginx/sites-enabled/

        sudo sed  -i  's/internal-Chatapp-venv-alb2-1481137299.us-east-2.elb.amazonaws.com/internal-test-alb2-785647307.us-east-2.elb.amazonaws.com/g'  fundoo

        sudo systemctl restart nginx
EOF

}

resource "aws_autoscaling_group" "Frontend" {
  launch_configuration = "${aws_launch_configuration.test-launch-config.name}"
  vpc_zone_identifier  = ["${var.subnet1}","${var.subnet2 }"]
  target_group_arns    = ["${var.target_group_arn1}"]
  health_check_type    = "EC2"
  
  min_size = 1
  max_size = 5

  tag {
    key                 = "Name"
    value               = "test-asg-frontend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_policy_up" {
	name = "web_policy_up"
	scaling_adjustment = 1
	adjustment_type = "ChangeInCapacity"
	cooldown = 600
	autoscaling_group_name = "${aws_autoscaling_group.Frontend.name}"
}

resource "aws_autoscaling_policy" "web_policy_down" {
	name = "web_policy_down"
	scaling_adjustment = -1
	adjustment_type = "ChangeInCapacity"
	cooldown = 600
	autoscaling_group_name = "${aws_autoscaling_group.Frontend.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up"{
	alarm_name = "web_cpu_alarm_up"
  statistic = "Average"
	comparison_operator = "GreaterThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	threshold = "60"

  dimensions = {
	  AutoScalingGroupName = "${aws_autoscaling_group.Frontend.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web_policy_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down"{
	alarm_name = "web_cpu_alarm_down"
  statistic = "Average"
	comparison_operator = "LessThanOrEqualToThreshold"
	evaluation_periods = "2"
	metric_name = "CPUUtilization"
	namespace = "AWS/EC2"
	period = "120"
	threshold = "20"

  dimensions = {
	  AutoScalingGroupName = "${aws_autoscaling_group.Frontend.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web_policy_down.arn}"]
}

resource "aws_security_group" "asg-sg1" {
  name   = "asg-sg1"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "asg_inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg1.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg1.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_database" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg1.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_inbound_backend" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg1.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "asg_outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.asg-sg1.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_lb_target_group" "target-group1" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "test-tg-public"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb" "aws-alb1" {
  name     = "test-alb"
  internal = false

  security_groups = [
    "${aws_security_group.alb-sg1.id}",
  ]

  subnets = [
    "${var.subnet1}",
    "${var.subnet2}",
  ]

  tags = {
    Name = "test-alb-public"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}


resource "aws_lb_listener" "test-alb-listner1" {
  load_balancer_arn = aws_lb.aws-alb1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn= aws_lb_target_group.target-group1.arn
  }
}


resource "aws_security_group" "alb-sg1" {
  name   = "alb-sg"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg1.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_database" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg1.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "inbound_backend" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg1.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb-sg1.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.alb-sg1.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


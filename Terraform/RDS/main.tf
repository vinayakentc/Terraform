
resource "aws_db_instance" "test-mysql" {
  identifier               = "database2"
  instance_class          = "${var.db_instance}"
  engine                  = "mysql"
  engine_version          = 5.7
  multi_az                = true
  storage_type            = "gp2"
  allocated_storage       = 20
  name                    = "ChatappDB"
  username                = "admin"
  password                = "ganeshchavan"
  apply_immediately       = "true"
  db_subnet_group_name    = "${aws_db_subnet_group.rds-db-subnet.name}"
  vpc_security_group_ids  = ["${aws_security_group.rds-sg.id}"]
  skip_final_snapshot  = "true" 
}

resource "aws_db_subnet_group" "rds-db-subnet" {
  name       = "rds-db-subnet"
  subnet_ids = ["${var.rds_subnet3}", "${var.rds_subnet4}"]
}

resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "rds-sg-rule" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.rds-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_rule" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.rds-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_ecr_repository" "ecr" {
  name = "containers-repository"
}

resource "aws_ecs_cluster" "ecs" {
  name = "orchestrator"
}

resource "aws_lb" "alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.alb_security_group}"]
  subnets            = ["${var.public_subnets}"]

  access_logs {
    bucket  = "${aws_s3_bucket.alb_logs.bucket}"
    prefix  = "test-alb"
    enabled = true
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "test-alb-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${var.vpc}"
  target_type = "instance"
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.alb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.id}"
    type             = "forward"
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "test-alb-logs"
  acl    = "private"
}

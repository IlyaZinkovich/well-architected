resource "aws_s3_bucket" "alb_logs" {
  bucket = "test-alb-logs"
  acl    = "private"
}

resource "aws_alb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.alb_security_groups}"]
  subnets            = ["${var.public_subnets}"]

  access_logs {
    bucket  = "${aws_s3_bucket.alb_logs.bucket}"
    prefix  = "${var.project_name}-alb"
    enabled = true
  }
}

resource "aws_alb_target_group" "blue" {
  name        = "${var.project_name}-blue-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${var.vpc}"
  target_type = "ip"
}

resource "aws_alb_target_group" "green" {
  name        = "${var.project_name}-green-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${var.vpc}"
  target_type = "ip"
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.alb.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.blue.id}"
    type             = "forward"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  role = "${aws_iam_role.ecs_task_execution_role.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/${var.project_name}-app"
}

data "template_file" "app_template" {
  template = "${file("./application/task.json.tpl")}"

  vars {
    app_name           = "${var.project_name}"
    fargate_cpu        = "${var.fargate_cpu}"
    fargate_memory     = "${var.fargate_memory}"
    aws_region         = "${var.aws_region}"
    app_port           = "${var.app_port}"
    ecr_repository_url = "${var.ecr_repository_url}"
    log_group          = "${aws_cloudwatch_log_group.log_group.name}"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app-task"
  execution_role_arn       = "${aws_iam_role.ecs_task_execution_role.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  container_definitions    = "${data.template_file.app_template.rendered}"
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.app_count}"
  launch_type     = "FARGATE"

  deployment_controller = {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups  = []
    subnets          = ["${var.private_subnets}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.blue.id}"
    container_name   = "${var.project_name}"
    container_port   = "${var.app_port}"
  }

  depends_on = [
    "aws_alb_listener.front_end",
    "aws_iam_role_policy.ecs_task_execution_role_policy"
  ]

  lifecycle {
    ignore_changes = [
      "task_definition",
      "load_balancer",
      "desired_count"
    ]
  }
}

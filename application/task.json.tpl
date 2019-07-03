[
  {
    "name": "${app_name}",
    "image": "${ecr_repository_url}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "hostPort": ${app_port},
        "protocol": "tcp",
        "containerPort": ${app_port}
      }
    ]
  }
]

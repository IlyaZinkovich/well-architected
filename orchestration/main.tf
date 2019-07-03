resource "aws_ecr_repository" "ecr" {
  name = "containers-repository"
}

resource "aws_ecs_cluster" "ecs" {
  name = "orchestrator"
}

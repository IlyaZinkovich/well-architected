output "ecr_repository_url" {
  value = "${aws_ecr_repository.ecr.repository_url}"
}

output "ecs_cluster" {
  value = "${aws_ecs_cluster.ecs.id}"
}

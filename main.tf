module "networking" {
  source = "./networking"
}

module "orchestration" {
  source = "./orchestration"
}

module "application" {
  source              = "./application"
  vpc                 = "${module.networking.vpc}"
  private_subnets     = "${module.networking.private_subnets}"
  public_subnets      = "${module.networking.public_subnets}"
  alb_security_groups = "${module.networking.alb_security_groups}"
  ecr_repository_url  = "${module.orchestration.ecr_repository_url}"
  ecs_cluster         = "${module.orchestration.ecs_cluster}"
}

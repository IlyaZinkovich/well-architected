module "networking" {
  source = "./networking"
}

module "orchestration" {
  source = "./orchestration"
  vpc = "${module.networking.vpc}"
  public_subnets = "${module.networking.public_subnets}"
  alb_security_group = "${module.networking.alb_security_group}"
}

module "application" {
  source = "./application"
}

module "networking" {
  source = "./networking"
}

module "application" {
  source             = "./application"
  vpc                = "${module.networking.vpc}"
  private_subnets    = "${module.networking.private_subnets}"
  public_subnets     = "${module.networking.public_subnets}"
  alb_security_group = "${module.networking.alb_security_group}"
}

module "vm" {
  source            = "./modules/vm"
  publicsubnets_id  = module.vpc.publicsubnets_id
  privatesubnets_id = module.vpc.privatesubnets_id
  vpc_id            = module.vpc.vpc_id
  count_slave = 2
  depends_on = [
    module.vpc
  ]
}

output test {
  value = module.vpc.publicsubnets_id
}

module "vpc" {
  source = "./modules/vpc"
}
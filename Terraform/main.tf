
#Configure the AWS Provider

provider "aws" {
  region     = "us-east-2"
  profile = "chatapp"
}

 module "vpc" {
   source = "./VPC"
   vpc_cidr = "10.0.0.0/16"
   public_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
   private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

module "rds" {
  source      = "./RDS"
  db_instance = "db.t2.micro"
  rds_subnet3 = "${module.vpc.subnet3}"
  rds_subnet4 = "${module.vpc.subnet4}"
  vpc_id      = "${module.vpc.vpc_id}"
}





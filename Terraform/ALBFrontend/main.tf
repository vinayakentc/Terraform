provider "aws" {
  region     = "us-east-2"
  profile = "chatapp"
}

module "albf" {
  source = "./ALBF"
  vpc_id = "vpc-0cc3748db645f4dea"
  subnet1 = "subnet-09031f08686d24edd"
  subnet2 = "subnet-02261f533b1fdda66"
  subnet3 = "subnet-054c76d7848025893"
  subnet4 = "subnet-09425cf721e99ce90"

  target_group_arn1 = "${module.albf.alb_target_group_arn1}"

}





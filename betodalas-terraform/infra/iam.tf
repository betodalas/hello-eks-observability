module "iam" {
  source = "./modules/iam"

  users = var.iam_users
}

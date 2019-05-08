# Edit these if required!!!
locals {
  app_name = "${element(concat(split("/", path.cwd)), length(concat(split("/", path.cwd)))-2 )}"

  team = "${local.app_name}"

  namespace = "monitoring"

  organisation = "cgws"

  environments = [
    "ops",
  ]

  costcode = "cotd"

  scaling_enabled = "false"
}

# Don't touch these!
locals {
  environment_types = {
    "rbt"      = "development"
    "absinthe" = "production"
    "ops"      = "production"
  }
}

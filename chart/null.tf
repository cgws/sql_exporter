data "null_data_source" "values_data" {
  count = "${length(local.environments)}"

  inputs = {
    IMAGE           = "${local.organisation}/${local.app_name}"
    APP_NAME        = "${local.app_name}"
    ENV_NAME        = "${local.environments[count.index]}"
    ENV_TYPE        = "${lookup(local.environment_types, local.environments[count.index])}"
    COSTCODE        = "${local.costcode}"
    SCALING_ENABLED = "${local.scaling_enabled == "" ? lookup(local.environment_types, local.environments[count.index]) == "production" ? "true" : "false" : local.scaling_enabled}"
  }
}

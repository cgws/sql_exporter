resource "local_file" "values_yamls" {
  count    = "${length(local.environments)}"
  content  = "${data.template_file.values.*.rendered[count.index]}"
  filename = "${local.app_name}/values-${local.environments[count.index]}.yaml"
}

data "template_file" "values" {
  count    = "${length(local.environments)}"
  template = "${file("./${local.app_name}/values-remote.yaml.tpl")}"

  vars = "${data.null_data_source.values_data.*.outputs[count.index]}"
}

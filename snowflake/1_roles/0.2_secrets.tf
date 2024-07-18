data "aws_secretsmanager_secret" "snowflake_cred" {
  arn = local.initialize_config["aws_secret"]
}

data "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = data.aws_secretsmanager_secret.snowflake_cred.id
}

locals {
  snowflake_admin = jsondecode(data.aws_secretsmanager_secret_version.secret_version.secret_string) 
}

# output "name" {
#   value = local.snowflake_admin.username
#   sensitive = true
# }
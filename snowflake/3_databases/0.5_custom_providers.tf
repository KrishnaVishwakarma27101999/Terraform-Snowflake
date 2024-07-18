
provider "snowflake" {
  alias    = "dba"
  account  = local.snowflake_admin.account
  user     = local.snowflake_admin.username
  password = local.snowflake_admin.password
  role     = local.initialize_config["dba"]
}
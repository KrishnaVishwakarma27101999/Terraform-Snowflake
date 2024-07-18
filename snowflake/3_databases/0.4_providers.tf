
provider "snowflake" {
  alias    = "accountadmin"
  account  = local.snowflake_admin.account
  user     = local.snowflake_admin.username
  password = local.snowflake_admin.password
  role     = local.initialize_config["accountadmin"]
}

provider "snowflake" {
  alias    = "sysadmin"
  account  = local.snowflake_admin.account
  user     = local.snowflake_admin.username
  password = local.snowflake_admin.password
  role     = local.initialize_config["sysadmin"]
}

provider "snowflake" {
  alias    = "useradmin"
  account  = local.snowflake_admin.account
  user     = local.snowflake_admin.username
  password = local.snowflake_admin.password
  role     = local.initialize_config["useradmin"]
}

provider "snowflake" {
  alias    = "securityadmin"
  account  = local.snowflake_admin.account
  user     = local.snowflake_admin.username
  password = local.snowflake_admin.password
  role     = local.initialize_config["securityadmin"]
}


provider "aws" {
  region = "eu-west-2"
}



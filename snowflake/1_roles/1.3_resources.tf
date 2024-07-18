############################ BUSINESS ROLES OBJECT ##################################################################
#1 Create business roles in snowflake
resource "snowflake_role" "bf_role" {
  provider = snowflake.useradmin
  for_each = toset(var.bf_role)

  name = each.value
}

#2 Grants business role hierarchy
resource "snowflake_grant_account_role" "bf_role_grants" {
  provider   = snowflake.useradmin
  for_each   = local.bf_role_grants
  depends_on = [snowflake_role.bf_role]

  role_name        = each.value.child_role
  parent_role_name = each.value.parent_role
}

#3 Grant account privilege object to business function role
resource "snowflake_grant_privileges_to_account_role" "account_object_grants_bf_role" {
  provider   = snowflake.accountadmin
  for_each   = local.account_object_grants_bf_role
  depends_on = [snowflake_grant_account_role.bf_role_grants]

  privileges        = [each.value.privilege]
  account_role_name = each.value.role_name
  on_account        = true

}

#4 Grant DB privilege object to business function role
resource "snowflake_grant_privileges_to_account_role" "db_object_grants_bf_role" {
  provider   = snowflake.accountadmin
  for_each   = local.db_object_grants_bf_role
  depends_on = [snowflake_grant_privileges_to_account_role.account_object_grants_bf_role]

  account_role_name = each.value.role_name
  privileges        = [each.value.privilege]
  on_account_object {
    object_type = "DATABASE" # All applications should be using DATABASE object_type
    object_name = each.value.db_name
  }
  with_grant_option = false
}
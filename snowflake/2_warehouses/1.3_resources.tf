
########################### WAREHOUSE OBJECT ##################################################################
#1 Create Warehouse
resource "snowflake_warehouse" "warehouse" {
  provider   = snowflake.dba
  for_each   = var.warehouse
  #   depends_on = [snowflake_grant_privileges_to_account_role.db_object_grants_bf_role]

  name                = each.key
  warehouse_size      = each.value[0]
  max_cluster_count   = each.value[1]
  min_cluster_count   = each.value[2]
  auto_suspend        = each.value[3]
  auto_resume         = each.value[4]
  initially_suspended = each.value[5]
}

#2 Create warehouse privilege object function role
resource "snowflake_role" "of_warehouse_privilege_role" {
  provider   = snowflake.useradmin
  for_each   = local.of_warehouse_privilege_role
  depends_on = [snowflake_warehouse.warehouse]

  name = "${each.value.warehouse_object_function_role}_${each.value.privilege}"

}



#3 Grants privileges to warehouse-privilege-role
resource "snowflake_grant_privileges_to_account_role" "of_warehouse_privilege_role" {
  provider   = snowflake.dba
  for_each   = local.of_warehouse_privilege_role
  depends_on = [snowflake_role.of_warehouse_privilege_role]

  account_role_name = "${each.value.warehouse_object_function_role}_${each.value.privilege}"
  privileges        = [each.value.privilege]
  on_account_object {
    object_name = each.value.warehouse_object_function_role
    object_type = "WAREHOUSE"
  }
}

#4 Grants wh-privilege-role to bf-role
resource "snowflake_grant_account_role" "warehouse_of_role_bf_role_hierarchy" {
  provider   = snowflake.useradmin
  for_each   = local.warehouse_of_role_bf_role_hierarchy
  depends_on = [snowflake_grant_privileges_to_account_role.of_warehouse_privilege_role]

  role_name        = each.value.of_warehouse_role
  parent_role_name = each.value.bf_role

}



# output "name" {
#   value = local.of_warehouse_privilege_role
# }
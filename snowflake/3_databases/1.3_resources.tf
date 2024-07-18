############################ DATABASE OBJECT ##################################################################
# Database Creation
resource "snowflake_database" "database" {
  provider   = snowflake.dba
  for_each   = var.db_config
  # depends_on = [snowflake_grant_account_role.warehouse_of_role_bf_role_hierarchy]

  name                        = each.key
  data_retention_time_in_days = 1
}

# Schema Creation
resource "snowflake_schema" "schema" {
  provider   = snowflake.dba
  for_each   = local.schema
  depends_on = [snowflake_database.database]

  name                = split(":", each.value)[1]
  database            = split(":", each.value)[0]
  data_retention_days = 1

}

#  Database schema privilege role creation
resource "snowflake_role" "db_privilege_category_role" {
  provider   = snowflake.useradmin
  for_each   = local.db_privilege_category_role
  depends_on = [snowflake_schema.schema]

  name = each.value

}

# Grant privileges on database to db-object-role 
resource "snowflake_grant_privileges_to_account_role" "filter_database_grants" {
  provider   = snowflake.dba
  for_each   = local.filter_database_grants
  depends_on = [snowflake_role.db_privilege_category_role]

  account_role_name = join("_", slice(split(":", each.value), 0, 3))
  privileges        = [reverse(split(":", each.value))[0]]
  on_account_object {
    object_name = split(":", each.value)[0]
    object_type = "DATABASE"
  }

}

# Grant privileges on schema on all objects to db-object-role 
resource "snowflake_grant_privileges_to_account_role" "filter_schema_all_object_grants" {
  provider   = snowflake.dba
  for_each   = local.filter_schema_all_object_grants
  depends_on = [snowflake_grant_privileges_to_account_role.filter_database_grants]

  account_role_name = "${each.value.database_name}_${each.value.schema_name}_${each.value.bf_privilege_category}"
  privileges        = each.value.privilege
  on_schema_object {
    all {
      in_schema          = "${each.value.database_name}.${each.value.schema_name}"
      object_type_plural = each.value.privilege_on
    }
  }
}

# Grant privileges on schema on future objects to db-object-role 
resource "snowflake_grant_privileges_to_account_role" "filter_schema_future_object_grants" {
  provider = snowflake.dba
  for_each = local.filter_schema_future_object_grants
  depends_on = [ snowflake_grant_privileges_to_account_role.filter_schema_all_object_grants ]

  account_role_name = "${each.value.database_name}_${each.value.schema_name}_${each.value.bf_privilege_category}"
  privileges = each.value.privilege
  on_schema_object {
    future {
      in_schema = "${each.value.database_name}.${each.value.schema_name}"
      object_type_plural = each.value.privilege_on
    }
  }  
}

# Grant privileges on schema on other objects to db-object-role 
resource "snowflake_grant_privileges_to_account_role" "filter_schema_other_object_grants" {
  provider = snowflake.dba
  for_each = local.filter_schema_other_object_grants
  depends_on = [ snowflake_grant_privileges_to_account_role.filter_schema_future_object_grants ]

  account_role_name = "${each.value.database_name}_${each.value.schema_name}_${each.value.bf_privilege_category}"
  privileges = each.value.privilege
  on_schema {
    schema_name = "${each.value.database_name}.${each.value.schema_name}"
  } 
}

# Grant db-object-role to bf-role
resource "snowflake_grant_account_role" "grant_of_role_bf_role_mapping" {
  provider = snowflake.useradmin
  for_each = local.grant_of_role_bf_role_mapping
  depends_on = [ snowflake_grant_privileges_to_account_role.filter_schema_other_object_grants ]

  role_name = each.value.of_role
  parent_role_name = each.value.bf_role
}

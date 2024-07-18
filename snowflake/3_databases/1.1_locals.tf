  ############################ DATABASE OBJECT ##################################################################
locals {

  #1 Generate db mapping 
  database_config = flatten([
    for database_name, schema_map_list in var.db_config : [
      for schema_name, role_privilege in schema_map_list : [
        for role_name, privilege_list in role_privilege : [
          for privilege in privilege_list : {
            schema_name   = split(":", schema_name)[0]
            database_name = database_name
            grant_to      = length(split(":", schema_name)) == 1 ? "DBA" : split(":", schema_name)[1]
            role_name     = role_name
            privilege     = privilege
          }
    ]]]
  ])

  #2 Generate Schema 
  schema = { for name in distinct([for database_config in local.database_config : "${database_config.database_name}:${database_config.schema_name}"]) : replace(name, ":", "_") => name }

  # Generate privilege mapping 
  db_schema_privilege_role_map = flatten([
    for database_schema_name in local.schema : [
      for bf_privilege_category, account_schema_privilege in var.db_privilege_role_grants : [
        for object_type, privilege_list in account_schema_privilege : [
          for privilege_on in privilege_list :
          "${database_schema_name}:${bf_privilege_category}:${object_type}:${privilege_on}"
        ]
    ]]
  ])

  #3 Generate database schema privilege role
  db_privilege_category_role = {
    for object_type_role_name_map in distinct([
      for object_type_role_name in local.db_schema_privilege_role_map :
      join("_", slice(split(":", object_type_role_name), 0, 3))
    ]) :
    object_type_role_name_map => object_type_role_name_map
  }

  #4 Filter Database privilege from var.db_privilege_role_grants
  filter_database_grants = {
    for db_grants in compact(flatten([
      for filter in local.db_schema_privilege_role_map : [
        split(":", filter)[3] == "DATABASE" ? filter : null
      ]
      ])
    ) : replace(db_grants, ":", "_") => db_grants
  }

  #5 Filter Schema and on all objects privilege from var.db_privilege_role_grants
  filter_schema_all_object_grants = {
    for db_grants in compact(flatten([
      for filter in local.db_schema_privilege_role_map : [
        split(":", filter)[3] == "SCHEMA" && strcontains(reverse(split(":", filter))[0], "ALL") ? filter : null
      ]
      ])) : replace(replace(db_grants, ":", "_"), " ", "_") => {
      database_name         = split(":", db_grants)[0]
      schema_name           = split(":", db_grants)[1]
      bf_privilege_category = split(":", db_grants)[2]
      object_type           = split(":", db_grants)[3]
      privilege             = split("-", split(":", db_grants)[4])
      privilege_on          = replace(split(":", db_grants)[5], "ALL ", "")
    }
  }

  #6 Filter Schema and on future objects privilege from var.db_privilege_role_grants
  filter_schema_future_object_grants = {
    for db_grants in compact(flatten([
      for filter in local.db_schema_privilege_role_map : [
        split(":", filter)[3] == "SCHEMA" && strcontains(reverse(split(":", filter))[0], "FUTURE") ? filter : null
      ]
      ])) : replace(replace(db_grants, ":", "_"), " ", "_") => {
      database_name         = split(":", db_grants)[0]
      schema_name           = split(":", db_grants)[1]
      bf_privilege_category = split(":", db_grants)[2]
      object_type           = split(":", db_grants)[3]
      privilege             = split("-", split(":", db_grants)[4])
      privilege_on          = replace(split(":", db_grants)[5], "FUTURE ", "")
    }
  }

  #6 Filter Schema and on other objects privilege from var.db_privilege_role_grants
  filter_schema_other_object_grants = {
    for db_grants in compact(flatten([
      for filter in local.db_schema_privilege_role_map : [
        split(":", filter)[3] == "SCHEMA" && !strcontains(reverse(split(":", filter))[0], "ALL") && !strcontains(reverse(split(":", filter))[0], "FUTURE") ? filter : null
      ]])) : replace(replace(db_grants, ":", "_"), " ", "_") => {
      database_name         = split(":", db_grants)[0]
      schema_name           = split(":", db_grants)[1]
      bf_privilege_category = split(":", db_grants)[2]
      object_type           = split(":", db_grants)[3]
      privilege             = split("-", split(":", db_grants)[4])
    }
  }



  grant_of_role_bf_role_mapping = {
    for role_map in flatten([
      for database_name, schema_role_privilege_list in var.db_config : [
        for schema_name, role_privilege_list in schema_role_privilege_list : [
          for role_name, privilege_list in role_privilege_list : [
            for privilege in privilege_list :
            "${database_name}:${split(":", schema_name)[0]}:${privilege}:${role_name}"
    ]]]]) :
    replace(role_map, ":", "_") => {
      of_role = join("_", slice(split(":", role_map), 0, 3))
      bf_role = split(":", role_map)[3]
    }
  }

  
}
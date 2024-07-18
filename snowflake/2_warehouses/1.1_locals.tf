
  ############################ WAREHOUSE OBJECT ##################################################################
locals {
  # Create warehouse object privilege role 
  of_warehouse_privilege_role = {
    for wh_of_role in flatten([
      for warehouse_name, warehouse_details in var.warehouse : [
        for warehouse_privilege in var.of_warehouse_privilege_role : [
          "${warehouse_name}:${warehouse_privilege}"
        ]
      ]
      ]) : replace("${wh_of_role}", ":", "_") => {
      warehouse_object_function_role = split(":", "${wh_of_role}")[0]
      privilege                      = split(":", "${wh_of_role}")[1]
    }
  }

  # Grants warehouse of role to business role 
  warehouse_of_role_bf_role_hierarchy = {
    for wh_privilege_role in flatten([
      for warehouse_name, warehouse_privilege in var.warehouse_of_role_bf_role_hierarchy : [
        for privileges, role_list in warehouse_privilege : [
          for role_name in role_list : [
            "${warehouse_name}:${role_name}:${privileges}"
          ]
      ]]
      ]) : replace("${wh_privilege_role}", ":", "_") => {
      of_warehouse_role = "${split(":", "${wh_privilege_role}")[0]}_${split(":", "${wh_privilege_role}")[2]}"
      bf_role           = split(":", "${wh_privilege_role}")[1]
    }
  }
}
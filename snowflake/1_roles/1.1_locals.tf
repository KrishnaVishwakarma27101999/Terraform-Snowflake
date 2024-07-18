############################ BUSINESS ROLES OBJECT ##################################################################

locals {

  # Generate the business function roles hierarchy object
  bf_role_grants = {
    for parent_child_mapping in flatten([
      for parent_role, child_role_list in var.bf_role_grants : [
        for child_role in child_role_list : [
          "${child_role}:${parent_role}"
        ]
      ]
      ]) : replace(parent_child_mapping, ":", "_") => {
      child_role : split(":", parent_child_mapping)[0]
      parent_role : split(":", parent_child_mapping)[1]
    }
  }

  # Grants account level privileges objects to business function role
  account_object_grants_bf_role = {
    for privilege_role_mapping in flatten([
      for privilege, role_list in var.account_object_grants_bf_role : [
        for role_name in role_list : [
          "${privilege}:${role_name}"
        ]
      ]
      ]) : replace(replace(privilege_role_mapping, ":", "_"), " ", "_") => {
      privilege : split(":", privilege_role_mapping)[0]
      role_name : split(":", privilege_role_mapping)[1]
    }
  }

  # Grants DB level privileges objects to business function role
  db_object_grants_bf_role = {
    for db_privilege_mapping in flatten([
      for privilege, role_db_list in var.db_object_grants_bf_role : [
        for role_name in role_db_list[0] : [
          for db_name in role_db_list[1] :
          "${db_name}:${role_name}:${privilege}"
        ]
      ]
      ]) : replace(replace(db_privilege_mapping, ":", "_"), " ", "_") => {
      db_name   = split(":", db_privilege_mapping)[0]
      role_name = split(":", db_privilege_mapping)[1]
      privilege = split(":", db_privilege_mapping)[2]
    }
  }

}
variable "warehouse" { type = map(list(string)) }
variable "of_warehouse_privilege_role" { type = list(string) }
variable "warehouse_of_role_bf_role_hierarchy" { type = map(map(list(string))) }



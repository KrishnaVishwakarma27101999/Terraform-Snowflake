variable "bf_role" { type = list(string) }
variable "bf_role_grants" { type = map(list(string)) }
variable "account_object_grants_bf_role" { type = map(list(string)) }
variable "db_object_grants_bf_role" { type = map(list(list(string))) }

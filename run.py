import json
import os

## Flatten Json
def flatten(data, key=None, *, seperator=":"):
    if isinstance(data, list):
        for item in data:
            yield from flatten(item, key)
    elif isinstance(data, dict):
        for k, v in data.items():
            if key:
                new_key = key + seperator + k
                yield from flatten(v, new_key)
            else:
                yield from flatten(v, k) 
    else:
        yield str(key)+":"+str(data)       

def run_terminal(terraform_state,chdir,backend_config_bucket,backend_config_key,backend_config_region):
    
    terraform_init = f"""terraform -chdir={chdir} init -reconfigure -backend-config="bucket={backend_config_bucket}" -backend-config="key={backend_config_key}" -backend-config="region={backend_config_region}" """
    os.system(terraform_init)

    if terraform_state == "create":    
        terraform_apply = f"""terraform -chdir={chdir} apply -auto-approve -var-file="../../terraform.tfvars" """
        os.system(terraform_apply)

    elif terraform_state == "destroy":
        terraform_destroy = f"""terraform -chdir={chdir} destroy -auto-approve -var-file="../../terraform.tfvars" """
        os.system(terraform_destroy)

def business_role_function_creation(snowflake_account):
    chdir = "snowflake/1_roles/"
    backend_tf_state_path = f"{snowflake_account}/roles/terraform.tfstate"
    config_key = ["bf_role", "bf_role_grants", "account_object_grants_bf_role", "db_object_grants_bf_role"]
    terraform_variable = " ".join([  jsn_key +"="+ json.dumps(config[jsn_key])+"\n\n\n"  for jsn_key in config_key])
    with open('terraform.tfvars', 'w') as terraform_var_file:
        terraform_var_file.write(terraform_variable)
    run_terminal(terraform_state,chdir,backend_config_bucket,backend_tf_state_path,backend_config_region)

def warehouse_object_function_creation(snowflake_account):
    chdir = "snowflake/2_warehouses/"
    backend_tf_state_path = f"{snowflake_account}/warehouses/terraform.tfstate"
    config_key = ["warehouse", "of_warehouse_privilege_role", "warehouse_of_role_bf_role_hierarchy"]
    terraform_variable = " ".join([ jsn_key +"="+ json.dumps(config[jsn_key])+"\n\n\n"  for jsn_key in config_key])
    with open('terraform.tfvars', 'w') as terraform_var_file:
        terraform_var_file.write(terraform_variable)
    run_terminal(terraform_state,chdir,backend_config_bucket,backend_tf_state_path,backend_config_region)

def database_object_function_creation(snowflake_account,terraform_state,db_name_key=None):
    chdir = "snowflake/3_databases/"
    if terraform_state == "create":
        for db_name in config["db_config"].items():
            if db_name_key == db_name[0]:
                backend_tf_state_path = f"{snowflake_account}/databases/{db_name_key.lower()}/terraform.tfstate"
                terraform_variable = "db_privilege_role_grants="+ json.dumps(config["db_privilege_role_grants"])+"\n\n\n"+ "db_config="+ json.dumps({db_name_key:db_name[1]})
                with open('terraform.tfvars', 'w') as terraform_var_file:
                    terraform_var_file.write(terraform_variable)
                # print(db_name_key,terraform_state)
                run_terminal(terraform_state,chdir,backend_config_bucket,backend_tf_state_path,backend_config_region)
    elif terraform_state == "destroy":
        for db_name,db_config_obj in config_backup["db_config"].items():
            if db_name_key == db_name:
                backend_tf_state_path = f"{snowflake_account}/databases/{db_name_key.lower()}/terraform.tfstate"
                terraform_variable =  "db_privilege_role_grants="+ json.dumps(config_backup["db_privilege_role_grants"])+"\n\n\n"+ "db_config="+ json.dumps({db_name_key:db_config_obj})
                with open('terraform.tfvars', 'w') as terraform_var_file:
                    terraform_var_file.write(terraform_variable)
                run_terminal(terraform_state,chdir,backend_config_bucket,backend_tf_state_path,backend_config_region)

## Change Snowflake account s3 state 
snowflake_account = "indicia-operations"

## set State
# terraform_state = "create"
terraform_state  = input('Please enter (create or destrory) : ')

## Set S3 bucket to store State files
backend_config_bucket = "indy-s3-dev-tf-state"
backend_config_region = "eu-west-2"

###########################################################33
## Config Path
config_state_path = "account/config.json"
config_state_backup_path = "account/config_backup.json"

## check config backup state exists or not 
# if not present, then new empty state is created
# Else old state will be used  
if not os.path.isfile(config_state_backup_path) or os.stat(config_state_backup_path).st_size == 0:
    with open(config_state_backup_path, "w") as outfile:
        json.dump({}, outfile) 

## Read Config
config = open(config_state_path)
config = json.load(config)

## Read Config_backup
config_backup = open(config_state_backup_path)
config_backup = json.load(config_backup)

## flatten Configs
flatten_config= [ keys for keys in flatten(config) if "db_config" in keys ]
flatten_config_backup = [ keys for keys in flatten(config_backup) if "db_config" in keys ]

## Check databases changes and destroy or create the object in snowflake 
db_diff_keys_list = []
if set(flatten_config) - set(flatten_config_backup):
    dbs_key = list(set([item.split(":")[1] for item in [*set(flatten_config) - set(flatten_config_backup)]]))
    db_diff_keys_list.extend(dbs_key)

if set(flatten_config_backup) - set(flatten_config):
    dbs_key = list(set([item.split(":")[1] for item in [*set(flatten_config_backup) - set(flatten_config)]]))
    db_diff_keys_list.extend(dbs_key)

config_db_key = list(set([db_key.split(":")[1] for db_key in flatten_config]))
config_db_key = [key+":"+"create" if key in config_db_key  else key+":"+"destroy"  for key in db_diff_keys_list  ]

## Checks if there is any changes in cofig files
if set(flatten_config) - set(flatten_config_backup) or set(flatten_config_backup) - set(flatten_config):

    if terraform_state == "create":
        # Create business function role in snowflake
        business_role_function_creation(snowflake_account)
        # Create warehouse object role in snowflake
        warehouse_object_function_creation(snowflake_account)            
        # Create database object role in snowflake
        for keys in config_db_key:
            database_object_function_creation(snowflake_account,keys.split(":")[1],keys.split(":")[0]) 

        with open(config_state_backup_path, "w") as outfile:
                json.dump(config, outfile)

elif terraform_state == "destroy":
    if os.path.isfile(config_state_backup_path) and len(config_backup) != 0:
        config_db_key= list(set([db_key.split(":")[1]+":"+"destroy" for db_key in flatten_config]))
        for keys in config_db_key:
            database_object_function_creation(snowflake_account,terraform_state,keys.split(":")[0]) 
        warehouse_object_function_creation(snowflake_account)
        business_role_function_creation(snowflake_account)
    
    os.remove(config_state_backup_path)

else:
    print("No New Changes")

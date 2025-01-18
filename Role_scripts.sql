/*
Author: Sadrul
Linkedin: https://www.linkedin.com/in/sadrulalom
Description: Role creation and grand warehouse usage permission
*/

USE ROLE ACCOUNTADMIN;

USE DATABASE snowflake_admin_db;
USE SCHEMA wh_mgt;

CREATE OR REPLACE PROCEDURE create_account_level_role(
-- Name of the resource monitor to create
role_name STRING,
-- The warehouse name that will be granted with usage permission with role
warehouse_name STRING
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
	// Declare a variable to store if the role exists
	var role_existing = false;
	
	// Check if the Role already exists
    //var check_sql = `SHOW ROLES LIKE '${ROLE_NAME}';`;
    var check_sql = `select * from snowflake.account_usage.roles where name ='${ROLE_NAME}';`
    var check_result = snowflake.execute({sqlText: check_sql});

    role_existing = check_result.next();

    //return role_existing;
    
    // Check if the role already exists
	if (!role_existing) {
		// Create the role if it does not exist
		var createRoleSql = `CREATE ROLE IF NOT EXISTS ${ROLE_NAME}`;
		snowflake.execute({sqlText: createRoleSql});
		if(WAREHOUSE_NAME == null ){
			// Grant permissions on the Resource Monitor to the specified role
			var grant_sql = `GRANT USAGE ON WAREHOUSE ${WAREHOUSE_NAME} TO ROLE ${ROLE_NAME}`;
			snowflake.execute({sqlText: grant_sql});
				
			return `Role ${ROLE_NAME} created and usage permission granted successfully.`;
		}
		return `Role ${ROLE_NAME} created successfully.`;
	} else {
		return `Role ${ROLE_NAME} already exists.`;
	}
$$;

-- create new role and grand warehouse usage permission to role
CALL create_account_level_role('ROLE_NAME','WAHREHOUSE_NAME');

e.g.
CALL create_account_level_role('DEV_ROLE','VW_DEV');


GRANT USAGE ON PROCEDURE create_account_level_role(STRING, STRING) TO {ROLE ROLE_NAME OR USER USER_NAME};

e.g. 
GRANT USAGE ON DATABASE snowflake_admin_db TO ROLE ROLE_NAME; 
GRANT USAGE ON DATABASE snowflake_admin_db TO USER USER_NAME;

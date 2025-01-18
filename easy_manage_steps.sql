/*
Author: Sadrul
Linkedin: https://www.linkedin.com/in/sadrulalom
Description: warehouse management through admin procedure
*/
1. create an admin role for using procedures
	CREATE ROLE IF NOT EXISTS rol_mgt;

2. grand permissions to role "rol_mgt"
	GRANT USAGE ON DATABASE snowflake_admin_db  TO ROLE rol_mgt;
	GRANT USAGE ON SCHEMA wh_mgt TO ROLE rol_mgt;

	GRANT USAGE ON PROCEDURE manage_virtual_warehouse(STRING,STRING,STRING,STRING,STRING,STRING,STRING,STRING) TO ROLE rol_mgt;

	GRANT USAGE ON PROCEDURE create_resource_monitor_proc(STRING,STRING,STRING,STRING) TO ROLE rol_mgt;

	GRANT USAGE ON PROCEDURE create_account_level_role(STRING, STRING) TO ROLE rol_mgt;

	GRANT USAGE ON PROCEDURE show_warehouse_metadata(STRING) TO ROLE rol_mgt;


2. Grand the role "rol_mgt" to user who will manage this admin activities.

	GRANT ROLE rol_mgt TO USER {user_name};

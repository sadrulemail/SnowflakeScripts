/*
Author: Sadrul
Linkedin: https://www.linkedin.com/in/sadrulalom
Description: Resource monitor for warehouse
*/

CREATE OR REPLACE PROCEDURE create_resource_monitor_proc(
    -- Name of the resource monitor to create
	monitor_name STRING,
	 -- Credit quota to be set for the monitor (e.g., '10' for 10 credits)
	credit_quota STRING,
	-- The role to which permissions will be granted
    role_name STRING,
	-- The warehouse name that will be associated with the resource monitor
    warehouse_name STRING
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var result = '';
    var monitor_exists = false;

    try {
        // Check if the resource monitor already exists
        var check_sql = `SHOW RESOURCE MONITORS LIKE :1`;
        var check_stmt = snowflake.createStatement({
            sqlText: check_sql,
            binds: [MONITOR_NAME]
        });
        var check_result = check_stmt.execute();
        
        monitor_exists = check_result.next();

        if (monitor_exists) {
            result = 'Resource Monitor already exists.';
        } else {
            // Create the Resource Monitor with a monthly schedule that starts immediately and has no end date
            var create_sql = `CREATE RESOURCE MONITOR ${MONITOR_NAME}
                              CREDIT_QUOTA = ${CREDIT_QUOTA}
							  FREQUENCY = 'MONTHLY' 
							  START_TIMESTAMP = 'IMMEDIATELY' 
							  TRIGGERS
								ON 90 PERCENT DO SUSPEND 
								ON 100 PERCENT DO SUSPEND_IMMEDIATE 
								ON 80 PERCENT DO NOTIFY;
							  `;
            var create_stmt = snowflake.createStatement({
                sqlText: create_sql
            });
            create_stmt.execute();
			result = 'Resource Monitor created successfully.';
			
			if (WAREHOUSE_NAME != null)){
				// Associate the Resource Monitor with the Warehouse
				var associate_sql = `ALTER WAREHOUSE ${WAREHOUSE_NAME} SET RESOURCE_MONITOR = ${MONITOR_NAME}`;
				var associate_stmt = snowflake.createStatement({
					sqlText: associate_sql
				});
				associate_stmt.execute();
				result = 'Resource Monitor created, scheduled to start immediately and associated with warehouse.';
			}
			
			
			if( ROLE_NAME != null && WAREHOUSE_NAME != null){
				// Grant permissions on the Resource Monitor to the specified role
				var grant_sql = `GRANT USAGE, MONITOR ON RESOURCE MONITOR ${MONITOR_NAME} TO ROLE ${ROLE_NAME}`;
				var grant_stmt = snowflake.createStatement({
					sqlText: grant_sql
				});
				grant_stmt.execute();

				result = 'Resource Monitor created, scheduled to start immediately, and permissions granted successfully.';
			}
        }
    } catch (err) {
        result = 'Failed: ' + err;
    }

    return result;
$$;

-- create resource monitor 
CALL create_resource_monitor_proc('resource_monitor_name',credit_quota,'role_name','virtual_warehouse_name');

e.g.
CALL create_resource_monitor_proc('warehouse_rs_monitor',750,'data_team','vw_data_team');



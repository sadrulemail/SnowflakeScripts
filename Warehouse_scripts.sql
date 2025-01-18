/*
Author: Sadrul
Linkedin: https://www.linkedin.com/in/sadrulalom
Description: warehouse management through admin procedure
*/
USE ROLE ACCOUNTADMIN;
-- create management db if not exist
CREATE DATABASE IF NOT EXISTS snowflake_admin_db;
-- create management schema if not exist
CREATE SCHEMA IF NOT EXISTS wh_mgt;


-- Create a table to log warehouse request
CREATE OR REPLACE TABLE warehouse_request (
    id INT AUTOINCREMENT,
    action STRING,
    wh_name STRING,
    req_data STRING,
    user_name STRING,
    timestamp TIMESTAMP
);

CREATE OR REPLACE PROCEDURE manage_virtual_warehouse(
    -- Action to perform: 'CREATE', 'MODIFY', or 'DROP'
    action STRING,
    -- Name of the virtual warehouse to create, modify, or drop
    wh_name STRING,
    -- Size of the warehouse (for create and modify actions, e.g., X-Small, Small, Medium, Large, X-Large, etc.)
    wh_size STRING DEFAULT NULL,
    -- Minimum number of clusters for multi-cluster warehouses (for create and modify actions)
    wh_min_cluster STRING DEFAULT NULL,
    -- Maximum number of clusters for multi-cluster warehouses (for create and modify actions)
    wh_max_cluster STRING DEFAULT NULL,
    -- Auto-suspend time (in seconds) to automatically suspend the warehouse when idle (for create and modify actions)
    auto_suspend STRING DEFAULT NULL,
    -- Auto-resume feature for the warehouse (for create and modify actions, true or false)
    auto_resume STRING DEFAULT NULL,
	-- Type of the virtual warehouse (e.g., STANDARD, SNOWPARK-OPTIMIZED)
    wh_type STRING DEFAULT NULL
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    var result = '';
	var is_success=0;
	// Create a list of values
	var w_size = ['X-SMALL', 'SMALL', 'MEDIUM', 'LARGE', 'X-LARGE', '2X-LARGE', '3X-LARGE', '4X-LARGE', '5X-LARGE', '6X-LARGE'];
	var w_type = ['STANDARD', 'SNOWPARK-OPTIMIZED'];
	
    try {
        

        if (ACTION == 'CREATE') {
            if (WH_NAME == null || WH_SIZE == null || WH_MIN_CLUSTER == null || WH_MAX_CLUSTER == null || AUTO_SUSPEND == null || AUTO_RESUME == null || WH_TYPE == null || !w_type.some(type => type.toLowerCase() === WH_TYPE.toLowerCase()) || !w_size.map(size => size.toLowerCase()).includes(WH_SIZE.toLowerCase())) {
                throw "All parameters are required for CREATE action with correct values.";
            }
			
			//CREATE WAREHOUSE IF NOT EXISTS
            var create_wh_sql = `CREATE WAREHOUSE ${WH_NAME}
                                    WITH 
                                        WAREHOUSE_SIZE = '${WH_SIZE}',
                                        MIN_CLUSTER_COUNT = ${WH_MIN_CLUSTER},
                                        MAX_CLUSTER_COUNT = ${WH_MAX_CLUSTER},
                                        AUTO_SUSPEND = ${AUTO_SUSPEND},
                                        AUTO_RESUME = ${AUTO_RESUME},
                                        WAREHOUSE_TYPE = '${WH_TYPE}';`;


            snowflake.execute({sqlText: create_wh_sql});
			is_success=1;
            result = "Virtual Warehouse created successfully.";
        } else if (ACTION == 'MODIFY') {
            if (WH_NAME == null) {
                throw "Warehouse name is required for MODIFY action.";
            }
            
            var modify_wh_sql = `ALTER WAREHOUSE ${WH_NAME} SET`;

            // Array to hold individual parameter settings
            var params = [];
            
            // Append only provided parameters
            if (WH_SIZE != null) {
                params.push(` WAREHOUSE_SIZE = '${WH_SIZE}'`);
            }
            if (WH_MIN_CLUSTER != null) {
                params.push(` MIN_CLUSTER_COUNT = ${WH_MIN_CLUSTER}`);
            }
            if (WH_MAX_CLUSTER != null) {
                params.push(` MAX_CLUSTER_COUNT = ${WH_MAX_CLUSTER}`);
            }
            if (AUTO_SUSPEND != null) {
                params.push(` AUTO_SUSPEND = ${AUTO_SUSPEND}`);
            }
            
            // Join the parameters with commas and append to the main SQL string
            modify_wh_sql += params.join(',');

            snowflake.execute({sqlText: modify_wh_sql});
			is_success=1;
            result = "Virtual Warehouse modified successfully.";
        } else if (ACTION == 'DROP') {
            if (WH_NAME == null) {
                throw "Warehouse name is required for DROP action.";
            }
            //DROP WAREHOUSE IF EXISTS
            var drop_wh_sql = `DROP WAREHOUSE ` + WH_NAME + `;`;
            snowflake.execute({sqlText: drop_wh_sql});
			is_success=1;
            result = "Virtual Warehouse dropped successfully.";
        } else {
            throw "Invalid ACTION specified. Use 'CREATE', 'MODIFY', or 'DROP'.";
        }

        if(is_success){
			
		// Create a JSON object with the parameter values
        var warehouseParams = {
            "wh_size": WH_SIZE,
            "wh_min_cluster": WH_MIN_CLUSTER,
            "wh_max_cluster": WH_MAX_CLUSTER,
            "auto_suspend": AUTO_SUSPEND,
            "auto_resume": AUTO_RESUME,
            "wh_type": WH_TYPE
        };
		// Convert the JSON object to a string (optional, for logging or passing to SQL)
        var warehouseParamsJson = JSON.stringify(warehouseParams);
		
		// Log the request to the warehouse_request table
        var log_sql = `INSERT INTO WAREHOUSE_REQUEST (ACTION, WH_NAME, REQ_DATA, USER_NAME, TIMESTAMP)
                       VALUES ('` + ACTION + `', '` + WH_NAME + `', '` + warehouseParamsJson + `', CURRENT_USER(), CURRENT_TIMESTAMP());`;
        snowflake.execute({sqlText: log_sql});
		}
    } catch(err) {
        result = "Failed: " + err;
    }

    return result;
$$;


-- check data
select * from WAREHOUSE_REQUEST order by id desc;

--Create a Virtual Warehouse
CALL manage_virtual_warehouse('CREATE', 'MY_NEW_VIRTUAL_WH', 'XSMALL', '1', '1', '60', 'TRUE', 'STANDARD'); 
--Modify an Existing Virtual Warehouse
CALL manage_virtual_warehouse( 'MODIFY', 'MY_NEW_VIRTUAL_WH', 'MEDIUM', '1', '1', '60', NULL, NULL ); 
-- Drop an Existing Virtual Warehouse
CALL manage_virtual_warehouse( 'DROP', 'MY_NEW_VIRTUAL_WH', NULL, NULL, NULL, NULL, NULL, NULL ); 


GRANT USAGE ON DATABASE snowflake_admin_db  TO {ROLE ROLE_NAME OR USER USER_NAME};
GRANT USAGE ON SCHEMA wh_mgt TO {ROLE ROLE_NAME OR USER USER_NAME};
GRANT USAGE ON WAREHOUSE my_new_virtual_wh  TO {ROLE ROLE_NAME OR USER USER_NAME};

GRANT USAGE ON PROCEDURE manage_virtual_warehouse(STRING,STRING,STRING,STRING,STRING,STRING,STRING) TO {ROLE ROLE_NAME OR USER USER_NAME};

e.g. 
GRANT USAGE ON DATABASE snowflake_admin_db TO ROLE ROLE_NAME; 
GRANT USAGE ON DATABASE snowflake_admin_db TO USER USER_NAME;

/*
-- Create a Catalog Integration
CALL catalog_integration_setup(
    'CREATE',
    'catalog_integration_name',
    'OBJECT_STORE',
    'ICEBERG',
    'TRUE'
);
OR
CALL catalog_integration_setup(
    action_task => 'CREATE',
    catalog_integration_name => 'catalog_integration_1',
    catalog_source => 'OBJECT_STORE',
    table_format => 'ICEBERG',
    enabled => 'TRUE'
);

-- Drop a Catalog Integration
CALL catalog_integration_setup(
    'DROP',
    'catalog_integration_name',
    '', -- Not required for DROP
    '', -- Not required for DROP
    ''  -- Not required for DROP
);
OR
CALL catalog_integration_setup(
    action_task => 'DROP',
    catalog_integration_name => 'catalog_integration_1',
    catalog_source => '',  -- Ignored for DROP
    table_format => '',   -- Ignored for DROP
    enabled => ''         -- Ignored for DROP
);

*/

-- drop procedure if exists catalog_integration_setup(string, string, string, string, string);

CREATE OR REPLACE PROCEDURE catalog_integration_setup(
    action_task string,                -- Action to perform: 'CREATE' or 'DROP'.
    catalog_integration_name string,  -- Name of the catalog integration to be created or dropped.
    catalog_source string,            -- Source of the catalog (e.g., OBJECT_STORE). Required for CREATE.
    table_format string,              -- Table format to be used (e.g., ICEBERG, DELTA). Required for CREATE.
    enabled string                    -- Whether the integration is enabled ('TRUE' or 'FALSE'). Required for CREATE.
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
try {
    var sql_command = "";

    // Determine the action (CREATE or DROP)
    if (ACTION_TASK.toUpperCase() === 'CREATE') {
        // Construct the SQL statement for CREATE CATALOG INTEGRATION
        sql_command = `
            CREATE CATALOG INTEGRATION ${CATALOG_INTEGRATION_NAME}
                CATALOG_SOURCE = ${CATALOG_SOURCE}
                TABLE_FORMAT = ${TABLE_FORMAT}
                ENABLED = ${ENABLED};
        `;
    } else if (ACTION_TASK.toUpperCase() === 'DROP') {
        // Construct the SQL statement for DROP CATALOG INTEGRATION
        sql_command = `DROP CATALOG INTEGRATION IF EXISTS ${CATALOG_INTEGRATION_NAME};`;
    } else {
        throw "Invalid action. Use 'CREATE' or 'DROP'.";
    }

    // Execute the SQL statement
    snowflake.execute({sqlText: sql_command});

    // Return success message based on the action
    if (ACTION_TASK.toUpperCase() === 'CREATE') {
        return "Catalog integration created successfully.";
    } else {
        return "Catalog integration dropped successfully.";
    }
} catch (err) {
    return "Failed to perform action: " + err.message;
}
$$;
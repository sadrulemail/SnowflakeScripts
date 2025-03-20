/*
-- Create an External Volume
CALL azure_external_volume_setup(
    'CREATE',
    'external_volume_name',
    'storage_location',
    'https://<storageaccount>.blob.core.windows.net',
    'my-azure-tenant-id'
);
--Drop an External Volume
CALL azure_external_volume_setup(
    'DROP',
    'external_volume_name',
    '', -- Not required for DROP
    '', -- Not required for DROP
    ''  -- Not required for DROP
);

*/

-- drop procedure if exists azure_external_volume_setup(string, string, string, string, string);

CREATE OR REPLACE PROCEDURE azure_external_volume_setup(
    ACTION_TASK string,                  -- Action task to perform: 'CREATE' or 'DROP'.
    external_volume_name string,      -- Name of the external volume to be created or dropped.
    storage_location_name string,     -- Name of the storage location within the external volume (required for CREATE).
    storage_base_url string,          -- Base URL of the Azure storage account (required for CREATE).
    azure_tenant_id string            -- Azure Active Directory (AAD) tenant ID for authentication (required for CREATE).
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
try {
    var sql_command = "";

    // Determine the ACTION_TASK (CREATE or DROP)
    if (ACTION_TASK.toUpperCase() === 'CREATE') {
        // Construct the SQL statement for CREATE EXTERNAL VOLUME
        sql_command = `
            CREATE EXTERNAL VOLUME ${EXTERNAL_VOLUME_NAME}
            STORAGE_LOCATIONS = (
                (
                    NAME = '${STORAGE_LOCATION_NAME}',
                    STORAGE_PROVIDER = 'AZURE',
                    STORAGE_BASE_URL = '${STORAGE_BASE_URL}',
                    AZURE_TENANT_ID = '${AZURE_TENANT_ID}'
                )
            );
        `;
    } else if (ACTION_TASK.toUpperCase() === 'DROP') {
        // Construct the SQL statement for DROP EXTERNAL VOLUME
        sql_command = `DROP EXTERNAL VOLUME IF EXISTS ${EXTERNAL_VOLUME_NAME};`;
    } else {
        throw "Invalid ACTION_TASK. Use 'CREATE' or 'DROP'.";
    }

    // Execute the SQL statement
    snowflake.execute({sqlText: sql_command});

    // Return success message based on the ACTION_TASK
    if (ACTION_TASK.toUpperCase() === 'CREATE') {
        return "External volume created successfully.";
    } else {
        return "External volume dropped successfully.";
    }
} catch (err) {
    return "Failed to perform ACTION_TASK: " + err.message;
}
$$;
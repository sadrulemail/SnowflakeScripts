/*
-- Create Catalog Integration and External Volume
CALL setup_integration_and_volume(
    action_task => 'CREATE',
    catalog_integration_name => 'my_catalog_integration',
    catalog_source => 'OBJECT_STORE',
    table_format => 'ICEBERG',
    enabled => 'TRUE',
    external_volume_name => 'my_external_volume',
    storage_location_name => 'my_storage_location',
    storage_base_url => 'https://mystorageaccount.blob.core.windows.net',
    azure_tenant_id => 'my-azure-tenant-id'
);

-- Drop Catalog Integration and External Volume
CALL setup_integration_and_volume(
    action_task => 'DROP',
    catalog_integration_name => 'my_catalog_integration',
    catalog_source => 'IGNORED_VALUE',  -- Ignored for DROP
    table_format => 'IGNORED_VALUE',    -- Ignored for DROP
    enabled => 'IGNORED_VALUE',         -- Ignored for DROP
    external_volume_name => 'my_external_volume',
    storage_location_name => 'IGNORED_VALUE',  -- Ignored for DROP
    storage_base_url => 'IGNORED_VALUE',      -- Ignored for DROP
    azure_tenant_id => 'IGNORED_VALUE'        -- Ignored for DROP
);

*/

-- drop procedure if exists setup_integration_and_volume(string, string, string, string, string, string, string, string, string);

CREATE OR REPLACE PROCEDURE setup_integration_and_volume(
    action_task string,                     -- Action to perform: 'CREATE' or 'DROP'.
    catalog_integration_name string,       -- Name of the catalog integration to be created or dropped.
    catalog_source string,                 -- Source of the catalog (e.g., OBJECT_STORE). Required for CREATE.
    table_format string,                   -- Table format to be used (e.g., ICEBERG, DELTA). Required for CREATE.
    enabled string,                        -- Whether the catalog integration is enabled ('TRUE' or 'FALSE'). Required for CREATE.
    external_volume_name string,           -- Name of the external volume to be created or dropped.
    storage_location_name string,          -- Name of the storage location within the external volume. Required for CREATE.
    storage_base_url string,               -- Base URL of the Azure storage account. Required for CREATE.
    azure_tenant_id string                 -- Azure Active Directory (AAD) tenant ID for authentication. Required for CREATE.
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
try {
    var result = "";

    // Call the catalog_integration_setup procedure
    var catalog_stmt = snowflake.createStatement({
        sqlText: `
            CALL catalog_integration_setup(
                action_task => ?,
                catalog_integration_name => ?,
                catalog_source => ?,
                table_format => ?,
                enabled => ?
            );
        `,
        binds: [ACTION_TASK, CATALOG_INTEGRATION_NAME, CATALOG_SOURCE, TABLE_FORMAT, ENABLED]
    });
    var catalog_result = catalog_stmt.execute();
    catalog_result.next(); // Move to the first row of the result set
    result += "Catalog Integration: " + catalog_result.getColumnValue(1) + "\n";

    // Call the azure_external_volume_setup procedure
    var volume_stmt = snowflake.createStatement({
        sqlText: `
            CALL azure_external_volume_setup(
                action_task => ?,
                external_volume_name => ?,
                storage_location_name => ?,
                storage_base_url => ?,
                azure_tenant_id => ?
            );
        `,
        binds: [ACTION_TASK, EXTERNAL_VOLUME_NAME, STORAGE_LOCATION_NAME, STORAGE_BASE_URL, AZURE_TENANT_ID]
    });
    var volume_result = volume_stmt.execute();
    volume_result.next(); // Move to the first row of the result set
    result += "External Volume: " + volume_result.getColumnValue(1) + "\n";

    return result;
} catch (err) {
    return "Failed to execute parent procedure: " + err.message;
}
$$;
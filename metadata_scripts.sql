-- drop procedure show_warehouse_metadata(STRING);
CREATE OR REPLACE PROCEDURE show_warehouse_metadata(
-- Name of the warehouse to show metadata
warehouse_name STRING
)
RETURNS TABLE ()
LANGUAGE SQL
AS
$$
DECLARE
  res RESULTSET;
BEGIN
  -- Construct and execute the SQL query with the filtering parameters
  res := (EXECUTE IMMEDIATE 'SHOW WAREHOUSES LIKE ' || '\'' || :warehouse_name || '\'');
  
  -- Return the result set as a table
  RETURN TABLE(res);
END;
$$;

-- call procedure to show metadata for a specific warehouse
call show_warehouse_metadata('warehouse_name');

e.g.
call show_warehouse_metadata('DWH_VW');

-- grant permission
GRANT USAGE ON PROCEDURE show_warehouse_metadata(STRING) TO {ROLE ROLE_NAME OR USER USER_NAME};

e.g. 
GRANT USAGE ON DATABASE snowflake_admin_db TO ROLE ROLE_NAME; 
GRANT USAGE ON DATABASE snowflake_admin_db TO USER USER_NAME;
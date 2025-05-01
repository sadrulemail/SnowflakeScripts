CREATE OR REPLACE PROCEDURE MANAGE_NETWORK_POLICY_ACCESS(
    OPERATION_TYPE STRING,      -- 'GRANT' or 'REVOKE'
    POLICY_NAME STRING,         -- Name of the network policy
    TARGET_TYPE STRING,         -- 'ACCOUNT', 'USER', or 'INTEGRATION'
    TARGET_NAME STRING DEFAULT NULL -- Name of user/integration (NULL for account)
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    /**
    
     * Examples:
     *   1. Grant to account:
     *      CALL MANAGE_NETWORK_POLICY_ACCESS('GRANT', 'CORP_POLICY', 'ACCOUNT');
     *   
     *   2. Grant to user:
     *      CALL MANAGE_NETWORK_POLICY_ACCESS('GRANT', 'CORP_POLICY', 'USER', 'ANALYST_1');
     *
     *   3. Revoke from integration:
     *      CALL MANAGE_NETWORK_POLICY_ACCESS('REVOKE', 'CORP_POLICY', 'INTEGRATION', 'API_CONNECTOR');
     */
    
    // Validate operation type
    const op = OPERATION_TYPE.toUpperCase();
    if (!['GRANT', 'REVOKE'].includes(op)) {
        return `Error: Invalid OPERATION_TYPE '${op}'. Must be 'GRANT' or 'REVOKE'.`;
    }
    
    // Validate target type
    const target = TARGET_TYPE.toUpperCase();
    if (!['ACCOUNT', 'USER', 'INTEGRATION'].includes(target)) {
        return `Error: Invalid TARGET_TYPE '${target}'. Must be 'ACCOUNT', 'USER', or 'INTEGRATION'.`;
    }
    
    // Validate target name when required
    if (target !== 'ACCOUNT' && !TARGET_NAME) {
        return `Error: TARGET_NAME is required for ${target} operations.`;
    }
    
    try {
        let sql;
        let successMessage;
        
        // Build the appropriate SQL command
        switch(target) {
            case 'ACCOUNT':
                if (op === 'GRANT') {
                    sql = `ALTER ACCOUNT SET NETWORK_POLICY = '${POLICY_NAME}'`;
                    successMessage = `Granted network policy '${POLICY_NAME}' to account`;
                } else {
                    sql = `ALTER ACCOUNT UNSET NETWORK_POLICY`;
                    successMessage = `Revoked network policy from account`;
                }
                break;
                
            case 'USER':
                if (op === 'GRANT') {
                    sql = `ALTER USER ${TARGET_NAME} SET NETWORK_POLICY = '${POLICY_NAME}'`;
                    successMessage = `Granted network policy '${POLICY_NAME}' to user '${TARGET_NAME}'`;
                } else {
                    sql = `ALTER USER ${TARGET_NAME} UNSET NETWORK_POLICY`;
                    successMessage = `Revoked network policy from user '${TARGET_NAME}'`;
                }
                break;
                
            case 'INTEGRATION':
                if (op === 'GRANT') {
                    sql = `ALTER INTEGRATION ${TARGET_NAME} SET NETWORK_POLICY = '${POLICY_NAME}'`;
                    successMessage = `Granted network policy '${POLICY_NAME}' to integration '${TARGET_NAME}'`;
                } else {
                    sql = `ALTER INTEGRATION ${TARGET_NAME} UNSET NETWORK_POLICY`;
                    successMessage = `Revoked network policy from integration '${TARGET_NAME}'`;
                }
                break;
        }
        
        // Execute the command
        snowflake.execute({sqlText: sql});
        return successMessage;
        
    } catch (err) {
        // Handle common error cases
        if (err.message.includes("does not exist")) {
            if (target === 'ACCOUNT') {
                return `Error: Network policy '${POLICY_NAME}' does not exist`;
            } else {
                return `Error: ${target.toLowerCase()} '${TARGET_NAME}' does not exist`;
            }
        }
        return `Error performing ${op.toLowerCase()} operation: ${err.message}`;
    }
$$;
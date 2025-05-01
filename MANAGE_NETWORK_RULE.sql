CREATE OR REPLACE PROCEDURE MANAGE_NETWORK_RULE(
    OPERATION_TYPE STRING,           -- OPERATION_TYPE type: 'CREATE', 'ALTER', or 'DROP'
    RULE_NAME STRING,           -- Name of the network rule
    RULE_TYPE STRING DEFAULT NULL, -- Type: 'IPV4' or 'HOST_PORT' (required for CREATE)
    RULE_MODE STRING DEFAULT 'INGRESS', -- Mode: 'INGRESS', 'EGRESS', or 'BLOCK'
    IP_LIST ARRAY DEFAULT NULL,  -- Array of IPs/host:ports (required for CREATE/ALTER)
    COMMENT STRING DEFAULT NULL  -- Optional description
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    /**
     * MANAGE_NETWORK_RULE - Comprehensive network rule management procedure
     * 
     * Standardized procedure for creating, altering, and dropping network rules
     * 
     * OPERATION_TYPE Types:
     *   - CREATE: Creates new network rule (requires RULE_TYPE and IP_LIST)
     *   - ALTER: Modifies existing rule (requires IP_LIST or COMMENT)
     *   - DROP: Removes a network rule
     * 
     * Examples:
     * 
     * 1. Create allow rule:
     *    CALL MANAGE_NETWORK_RULE('CREATE', 'CORP_IPS', 'IPV4', 'INGRESS',
     *       ARRAY_CONSTRUCT('192.0.2.0/24'), 'Corporate office range');
     * 
     * 2. Alter rule (update IPs):
     *    CALL MANAGE_NETWORK_RULE('ALTER', 'CORP_IPS', NULL, NULL,
     *       ARRAY_CONSTRUCT('192.0.2.0/24', '203.0.113.10/32'));
     * 
     * 3. Drop rule:
     *    CALL MANAGE_NETWORK_RULE('DROP', 'CORP_IPS');
     */
    
    // Validate OPERATION_TYPE type
    const op = OPERATION_TYPE.toUpperCase();
    if (!['CREATE', 'ALTER', 'DROP'].includes(op)) {
        return `Error: Invalid OPERATION_TYPE '${op}'. Must be CREATE, ALTER, or DROP.`;
    }
    
    // Validate rule name
    if (!RULE_NAME) {
        return "Error: Rule name is required for all OPERATION_TYPEs.";
    }
    
    let sql = "";
    
    try {
        // Handle DROP OPERATION_TYPE
        if (op === 'DROP') {
            sql = `DROP NETWORK RULE IF EXISTS ${RULE_NAME}`;
            snowflake.execute({sqlText: sql});
            return `Successfully dropped network rule: ${RULE_NAME}`;
        }
        
        // Validate IP_LIST for CREATE/ALTER
        if ((op === 'CREATE' || op === 'ALTER') && (!IP_LIST || IP_LIST.length === 0)) {
            return "Error: IP_LIST is required for CREATE and ALTER OPERATION_TYPEs.";
        }
        
        // Validate RULE_TYPE for CREATE
        if (op === 'CREATE' && !RULE_TYPE) {
            return "Error: RULE_TYPE is required for CREATE OPERATION_TYPE.";
        }
        
        // Format IP list
        const formattedIPs = IP_LIST.map(ip => `'${ip.replace(/'/g, "''")}'`).join(', ');
        
        // Handle CREATE OPERATION_TYPE
        if (op === 'CREATE') {
            const type = RULE_TYPE.toUpperCase();
            if (!['IPV4', 'HOST_PORT'].includes(type)) {
                return "Error: Invalid RULE_TYPE. Must be IPV4 or HOST_PORT.";
            }
            
            const mode = RULE_MODE.toUpperCase();
            if (!['INGRESS', 'EGRESS', 'BLOCK'].includes(mode)) {
                return "Error: Invalid RULE_MODE. Must be INGRESS, EGRESS, or BLOCK.";
            }
            
            sql = `CREATE NETWORK RULE ${RULE_NAME}\n` +
                  `  TYPE = '${type}'\n` +
                  `  MODE = '${mode}'\n` +
                  `  VALUE_LIST = (${formattedIPs})`;
            
            if (COMMENT) {
                sql += `\n  COMMENT = '${COMMENT.replace(/'/g, "''")}'`;
            }
            
            snowflake.execute({sqlText: sql});
            return `Created ${mode.toLowerCase()} network rule '${RULE_NAME}' ` +
                   `with ${IP_LIST.length} ${type === 'IPV4' ? 'IPs' : 'host:ports'}`;
        }
        // Handle ALTER OPERATION_TYPE
        else if (op === 'ALTER') {
            sql = `ALTER NETWORK RULE ${RULE_NAME} SET\n` +
                  `  VALUE_LIST = (${formattedIPs})`;
            
            if (COMMENT) {
                sql += `\n  COMMENT = '${COMMENT.replace(/'/g, "''")}'`;
            }
            
            snowflake.execute({sqlText: sql});
            return `Updated network rule '${RULE_NAME}' with ${IP_LIST.length} entries`;
        }
        
    } catch (err) {
        return `Error ${op.toLowerCase()}ing network rule: ${err}\nSQL: ${sql}`;
    }
$$;
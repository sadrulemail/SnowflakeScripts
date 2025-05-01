CREATE OR REPLACE PROCEDURE MANAGE_NETWORK_POLICY(
    OPERATION_TYPE STRING,      -- Operation to perform: 'CREATE', 'ALTER', or 'DROP'
    POLICY_NAME STRING,         -- Name of the network policy to create/alter/drop
    ALLOWED_IP_LIST ARRAY,      -- Array of allowed IP addresses/CIDR ranges (e.g., ['192.168.1.0/24'])
    BLOCKED_IP_LIST ARRAY,      -- Array of blocked IP addresses/CIDR ranges
    ALLOWED_NETWORK_RULE_LIST ARRAY, -- Array of allowed network rules (e.g., ['AWS_US_WEST_2'])
    BLOCKED_NETWORK_RULE_LIST ARRAY, -- Array of blocked network rules (e.g., ['TOR_EXIT_NODES'])
    COMMENT STRING              -- Optional description for the policy
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    /**

     * Examples:
				CALL CREATE_ADVANCED_NETWORK_POLICY(
				'CREATE',
				'CORPORATE_ACCESS_POLICY',
				ARRAY_CONSTRUCT('192.168.1.0/24', '10.0.0.0/16'),
				ARRAY_CONSTRUCT(),
				ARRAY_CONSTRUCT('AWS_US_WEST_2'),
				ARRAY_CONSTRUCT('TOR_EXIT_NODES'),
				'Corporate access policy with cloud region restrictions'
			);

			CALL CREATE_ADVANCED_NETWORK_POLICY(
				'ALTER',
				'CORPORATE_ACCESS_POLICY',
				ARRAY_CONSTRUCT('192.168.1.0/24', '10.0.0.0/16', '172.16.0.0/16'), -- Added new range
				ARRAY_CONSTRUCT('192.168.1.205'), -- Added blocked IP
				ARRAY_CONSTRUCT('AWS_US_WEST_2', 'AZURE_EAST_US'), -- Added Azure region
				ARRAY_CONSTRUCT('TOR_EXIT_NODES'),
				'Updated corporate access policy with new IP ranges'
			);

			CALL CREATE_ADVANCED_NETWORK_POLICY(
				'DROP',
				'CORPORATE_ACCESS_POLICY',
				ARRAY_CONSTRUCT(), -- Ignored for DROP
				ARRAY_CONSTRUCT(), -- Ignored for DROP
				ARRAY_CONSTRUCT(), -- Ignored for DROP
				ARRAY_CONSTRUCT(), -- Ignored for DROP
				'' -- Ignored for DROP
			);
     */
    
    // Validate operation type
    const validOperations = ["CREATE", "ALTER", "DROP"];
    if (!validOperations.includes(OPERATION_TYPE.toUpperCase())) {
        return `Error: Invalid OPERATION_TYPE. Must be one of: ${validOperations.join(", ")}`;
    }
    
    // Validate policy name for all operations except DROP
    if (OPERATION_TYPE.toUpperCase() !== "DROP" && (!POLICY_NAME || POLICY_NAME.trim() === "")) {
        return "Error: Policy name cannot be empty";
    }
    
    // Handle DROP operation
    if (OPERATION_TYPE.toUpperCase() === "DROP") {
        try {
            const sql = `DROP NETWORK POLICY IF EXISTS ${POLICY_NAME}`;
            snowflake.execute({sqlText: sql});
            return `Successfully dropped network policy: ${POLICY_NAME}`;
        } catch (err) {
            return `Error dropping network policy: ${err}`;
        }
    }
    
    // For CREATE and ALTER operations, build the appropriate SQL
    const clauses = [];
    
    if (ALLOWED_IP_LIST && ALLOWED_IP_LIST.length > 0) {
        clauses.push("ALLOWED_IP_LIST = (" + 
            ALLOWED_IP_LIST.map(ip => `'${ip}'`).join(",") + ")");
    }
    
    if (BLOCKED_IP_LIST && BLOCKED_IP_LIST.length > 0) {
        clauses.push("BLOCKED_IP_LIST = (" + 
            BLOCKED_IP_LIST.map(ip => `'${ip}'`).join(",") + ")");
    }
    
    if (ALLOWED_NETWORK_RULE_LIST && ALLOWED_NETWORK_RULE_LIST.length > 0) {
        clauses.push("ALLOWED_NETWORK_RULE_LIST = (" + 
            ALLOWED_NETWORK_RULE_LIST.map(rule => `'${rule}'`).join(",") + ")");
    }
    
    if (BLOCKED_NETWORK_RULE_LIST && BLOCKED_NETWORK_RULE_LIST.length > 0) {
        clauses.push("BLOCKED_NETWORK_RULE_LIST = (" + 
            BLOCKED_NETWORK_RULE_LIST.map(rule => `'${rule}'`).join(",") + ")");
    }
    
    if (COMMENT) {
        clauses.push(`COMMENT = '${COMMENT.replace(/'/g, "''")}'`);
    }
    
    // Validate at least one parameter is provided for CREATE/ALTER (except COMMENT)
    const nonCommentClauses = clauses.filter(c => !c.startsWith("COMMENT"));
    if (OPERATION_TYPE.toUpperCase() !== "DROP" && nonCommentClauses.length === 0) {
        return "Error: Must specify at least one parameter (allowed/blocked IPs or network rules)";
    }
    
    try {
        let sql;
        if (OPERATION_TYPE.toUpperCase() === "CREATE") {
            sql = `CREATE OR REPLACE NETWORK POLICY ${POLICY_NAME} ${clauses.join(" ")}`;
        } else { // ALTER
            sql = `ALTER NETWORK POLICY ${POLICY_NAME} SET ${clauses.join(" ")}`;
        }
        
        snowflake.execute({sqlText: sql});
        return `Successfully ${OPERATION_TYPE.toLowerCase()}ed network policy: ${POLICY_NAME}`;
    } catch (err) {
        return `Error ${OPERATION_TYPE.toLowerCase()}ing network policy: ${err}`;
    }
$$;
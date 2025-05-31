CREATE OR REPLACE PROCEDURE CHECK_AND_RESET_PASSWORD(service_account_name VARCHAR)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
    // Function to generate a random password
    function generateRandomPassword() {
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+";
        let password = "";
        for (let i = 0; i < 16; i++) {
            password += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return password;
    }

    // Main procedure logic
    try {
        // Convert service account name to uppercase
        const accountNameUpper = SERVICE_ACCOUNT_NAME.toUpperCase();
        
        // Check if user exists and get password info in one query
        let query = `
            SELECT 
                DATEDIFF('DAY', CURRENT_TIMESTAMP(), 
                EXPIRES_AT) AS DAYS_REMAINING,
                EXPIRES_AT AS EXPIRATION_DATE
            FROM SNOWFLAKE.ACCOUNT_USAGE.USERS 
            WHERE NAME = '${accountNameUpper}' AND DELETED_ON IS NULL AND DISABLED = FALSE`;
        
        let result = snowflake.execute({
            sqlText: query
        });
        
        if (result.next()) {
            let daysRemaining = result.getColumnValue(1);
            let expirationDate = new Date(result.getColumnValue(2));
            
            if (daysRemaining > 0) {
                return `Password for user '${accountNameUpper}' expires in ${daysRemaining} days (on ${expirationDate.toISOString().split('T')[0]}).`;
            } else {
                // Password expired - generate new one and reset
                let newPassword = generateRandomPassword();
                
                // Reset password with proper escaping
                snowflake.execute({
                    sqlText: `ALTER USER IF EXISTS "${accountNameUpper}" SET PASSWORD = '${newPassword}' MUST_CHANGE_PASSWORD = FALSE`
                });
                
                return `Password for user '${accountNameUpper}' was expired. It has been reset to: ${newPassword}.`;
            }
        } else {
            return `Error: User '${accountNameUpper}' does not exist or you lack permissions to view this user.`;
        }
    } catch (err) {
        return `Error: ${err}`;
    }
$$;
#!/usr/bin/env php
<?php
/**
 * WordPress Problematic Plugin Deactivator
 *
 * PURPOSE: Safely deactivate SSL/security plugins from WordPress database
 *          before migration to CloudFront/ALB architecture
 *
 * USAGE:
 *   php deactivate-problematic-plugins.php database.sql > database-fixed.sql
 *
 *   OR connect directly to MySQL:
 *   php deactivate-problematic-plugins.php --host=localhost --user=root --pass=password --db=wordpress
 *
 * WHAT IT DOES:
 *   1. Finds the active_plugins option in the database/SQL file
 *   2. Unserializes the PHP array
 *   3. Removes problematic plugins
 *   4. Re-serializes with correct string lengths
 *   5. Outputs fixed SQL or updates database directly
 */

// Plugins to deactivate (cause redirect loops or block requests)
$PROBLEMATIC_PLUGINS = [
    // SSL/HTTPS redirect plugins
    'really-simple-ssl/rlrsssl-really-simple-ssl.php',
    'really-simple-ssl-pro/really-simple-ssl-pro.php',
    'wordpress-https/wordpress-https.php',
    'ssl-insecure-content-fixer/ssl-insecure-content-fixer.php',
    'wp-force-ssl/wp-force-ssl.php',
    'easy-https-redirection/easy-https-redirection.php',
    'https-redirection/https-redirection.php',
    'ssl-zen/ssl_zen.php',

    // Security plugins that may block requests
    'wordfence/wordfence.php',
    'better-wp-security/better-wp-security.php',
    'ithemes-security-pro/ithemes-security-pro.php',
    'all-in-one-wp-security-and-firewall/wp-security.php',
    'sucuri-scanner/sucuri.php',
    'bulletproof-security/bulletproof-security.php',
    'cerber-security/cerber.php',
    'defender-security/defender-security.php',

    // LDAP/Authentication plugins (can cause login issues)
    'ldap-login-for-intranet-sites/developer.php',
    'simple-ldap-login/simple-ldap-login.php',
    'active-directory-integration/ad-integration.php',

    // Maintenance/Coming Soon plugins (can block site)
    'coming-soon/coming-soon.php',
    'starter-templates/starter-templates.php',
];

function deactivatePlugins($serializedPlugins, $pluginsToRemove) {
    // Unserialize the active_plugins array
    $plugins = @unserialize($serializedPlugins);

    if ($plugins === false) {
        fwrite(STDERR, "ERROR: Could not unserialize active_plugins\n");
        return $serializedPlugins;
    }

    if (!is_array($plugins)) {
        fwrite(STDERR, "ERROR: active_plugins is not an array\n");
        return $serializedPlugins;
    }

    $removed = [];
    $originalCount = count($plugins);

    // Remove problematic plugins
    foreach ($plugins as $key => $plugin) {
        foreach ($pluginsToRemove as $badPlugin) {
            if (stripos($plugin, $badPlugin) !== false || $plugin === $badPlugin) {
                $removed[] = $plugin;
                unset($plugins[$key]);
                break;
            }
        }
    }

    // Re-index array to maintain proper serialization
    $plugins = array_values($plugins);

    // Report what was removed
    if (!empty($removed)) {
        fwrite(STDERR, "DEACTIVATED " . count($removed) . " plugins:\n");
        foreach ($removed as $p) {
            fwrite(STDERR, "  - $p\n");
        }
    } else {
        fwrite(STDERR, "No problematic plugins found in active_plugins\n");
    }

    fwrite(STDERR, "Active plugins: $originalCount -> " . count($plugins) . "\n");

    // Re-serialize
    return serialize($plugins);
}

function processSQL($inputFile) {
    global $PROBLEMATIC_PLUGINS;

    $content = file_get_contents($inputFile);
    if ($content === false) {
        fwrite(STDERR, "ERROR: Could not read file: $inputFile\n");
        exit(1);
    }

    // Find and fix the active_plugins INSERT statement
    $pattern = "/(INSERT INTO `?wp_options`?[^;]*option_name[^;]*'active_plugins'[^;]*VALUES[^;]*\([^,]*,\s*')([^']+)(')/i";

    if (preg_match($pattern, $content, $matches)) {
        $originalSerialized = $matches[2];
        // Unescape the SQL string
        $unescaped = str_replace("\\'", "'", $originalSerialized);
        $unescaped = str_replace("\\\\", "\\", $unescaped);

        $fixedSerialized = deactivatePlugins($unescaped, $PROBLEMATIC_PLUGINS);

        // Re-escape for SQL
        $escaped = str_replace("\\", "\\\\", $fixedSerialized);
        $escaped = str_replace("'", "\\'", $escaped);

        $content = preg_replace($pattern, '${1}' . $escaped . '${3}', $content);
    } else {
        // Try UPDATE statement pattern
        $pattern = "/(UPDATE `?wp_options`? SET option_value\s*=\s*')([^']+)('\s*WHERE option_name\s*=\s*'active_plugins')/i";

        if (preg_match($pattern, $content, $matches)) {
            $originalSerialized = $matches[2];
            $unescaped = str_replace("\\'", "'", $originalSerialized);
            $unescaped = str_replace("\\\\", "\\", $unescaped);

            $fixedSerialized = deactivatePlugins($unescaped, $PROBLEMATIC_PLUGINS);

            $escaped = str_replace("\\", "\\\\", $fixedSerialized);
            $escaped = str_replace("'", "\\'", $escaped);

            $content = preg_replace($pattern, '${1}' . $escaped . '${3}', $content);
        } else {
            fwrite(STDERR, "WARNING: Could not find active_plugins in SQL file\n");
        }
    }

    // Also add the CloudFront fix SQL at the end
    $cloudfront_fixes = "

-- ============================================================================
-- AUTO-ADDED: CloudFront/ALB Migration Fixes
-- ============================================================================

-- Disable Really Simple SSL
UPDATE wp_options SET option_value = '' WHERE option_name = 'rlrsssl_options';
DELETE FROM wp_options WHERE option_name LIKE 'rsssl_%';
DELETE FROM wp_options WHERE option_name LIKE 'rlrsssl_%';

-- Disable Wordfence firewall (if exists)
UPDATE wp_wfconfig SET val = '0' WHERE name = 'firewallEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'liveTrafficEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'loginSecurityEnabled';

-- Disable iThemes Security SSL
UPDATE wp_options SET option_value = '' WHERE option_name = 'itsec-ssl';

-- ============================================================================
";

    $content .= $cloudfront_fixes;

    echo $content;
}

function connectAndFix($host, $user, $pass, $db) {
    global $PROBLEMATIC_PLUGINS;

    $mysqli = new mysqli($host, $user, $pass, $db);

    if ($mysqli->connect_error) {
        fwrite(STDERR, "Connection failed: " . $mysqli->connect_error . "\n");
        exit(1);
    }

    // Get current active_plugins
    $result = $mysqli->query("SELECT option_value FROM wp_options WHERE option_name = 'active_plugins'");

    if (!$result || $result->num_rows === 0) {
        fwrite(STDERR, "ERROR: Could not find active_plugins in database\n");
        exit(1);
    }

    $row = $result->fetch_assoc();
    $originalSerialized = $row['option_value'];

    $fixedSerialized = deactivatePlugins($originalSerialized, $PROBLEMATIC_PLUGINS);

    // Update the database
    $stmt = $mysqli->prepare("UPDATE wp_options SET option_value = ? WHERE option_name = 'active_plugins'");
    $stmt->bind_param("s", $fixedSerialized);

    if ($stmt->execute()) {
        fwrite(STDERR, "SUCCESS: Updated active_plugins in database\n");
    } else {
        fwrite(STDERR, "ERROR: Failed to update active_plugins\n");
    }

    // Run additional fixes
    $fixes = [
        "UPDATE wp_options SET option_value = '' WHERE option_name = 'rlrsssl_options'",
        "DELETE FROM wp_options WHERE option_name LIKE 'rsssl_%'",
        "DELETE FROM wp_options WHERE option_name LIKE 'rlrsssl_%'",
        "UPDATE wp_wfconfig SET val = '0' WHERE name = 'firewallEnabled'",
        "UPDATE wp_wfconfig SET val = '0' WHERE name = 'liveTrafficEnabled'",
        "UPDATE wp_options SET option_value = '' WHERE option_name = 'itsec-ssl'",
    ];

    foreach ($fixes as $sql) {
        if ($mysqli->query($sql)) {
            fwrite(STDERR, "Executed: " . substr($sql, 0, 60) . "...\n");
        }
    }

    $mysqli->close();
    fwrite(STDERR, "Database fixes completed!\n");
}

// Main execution
if ($argc < 2) {
    echo "Usage:\n";
    echo "  Process SQL file:  php $argv[0] database.sql > database-fixed.sql\n";
    echo "  Direct DB update:  php $argv[0] --host=localhost --user=root --pass=password --db=wordpress\n";
    exit(1);
}

// Check if connecting directly to database
if (strpos($argv[1], '--host=') === 0) {
    $host = $user = $pass = $db = '';

    foreach ($argv as $arg) {
        if (strpos($arg, '--host=') === 0) $host = substr($arg, 7);
        if (strpos($arg, '--user=') === 0) $user = substr($arg, 7);
        if (strpos($arg, '--pass=') === 0) $pass = substr($arg, 7);
        if (strpos($arg, '--db=') === 0) $db = substr($arg, 5);
    }

    if (empty($host) || empty($user) || empty($db)) {
        fwrite(STDERR, "ERROR: Missing required database parameters\n");
        exit(1);
    }

    connectAndFix($host, $user, $pass, $db);
} else {
    // Process SQL file
    processSQL($argv[1]);
}

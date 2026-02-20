<?php
/**
 * Plugin Name: BBWS Platform - Test Email Redirect
 * Description: Redirects all WordPress emails to test address in non-production environments
 * Version: 1.0.0
 * Author: BBWS Platform Team
 */

/**
 * Intercept ALL email sending in dev/sit environments
 *
 * This prevents accidentally sending test emails to real customers/business owners
 * during testing and QA phases.
 *
 * Configuration via wp-config.php:
 * - TEST_EMAIL_REDIRECT: Email address to receive all test emails
 * - WP_ENV: Environment identifier (dev, sit, prod)
 */

// Only activate in non-production environments
$wp_env = defined('WP_ENV') ? WP_ENV : 'prod';

if (!in_array($wp_env, ['dev', 'sit'])) {
    return; // Don't load in production
}

// Get test email from wp-config.php or use default
$test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : 'tebogo@bigbeard.co.za';

/**
 * Redirect all WordPress emails to test address
 *
 * Priority 999 ensures this runs after all other email filters
 */
add_filter('wp_mail', function($args) use ($test_email, $wp_env) {
    // Store original recipient(s) for reference
    $original_to = is_array($args['to']) ? implode(', ', $args['to']) : $args['to'];

    // Redirect to test email
    $args['to'] = $test_email;

    // Add environment prefix to subject
    $env_label = strtoupper($wp_env);
    if (strpos($args['subject'], "[TEST - ") === false) {
        $args['subject'] = "[TEST - {$env_label}] " . $args['subject'];
    }

    // Prepend original recipient info to message body
    $original_recipient_note = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    $original_recipient_note .= "TEST EMAIL REDIRECT - {$env_label} ENVIRONMENT\n";
    $original_recipient_note .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";
    $original_recipient_note .= "Original Recipient(s): {$original_to}\n";
    $original_recipient_note .= "Redirected To: {$test_email}\n";
    $original_recipient_note .= "Environment: {$env_label}\n";
    $original_recipient_note .= "Timestamp: " . current_time('Y-m-d H:i:s') . "\n\n";
    $original_recipient_note .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    $original_recipient_note .= "ORIGINAL MESSAGE BELOW:\n";
    $original_recipient_note .= "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

    // Handle both HTML and plain text emails
    if (isset($args['headers']) && is_array($args['headers'])) {
        $is_html = false;
        foreach ($args['headers'] as $header) {
            if (stripos($header, 'Content-Type: text/html') !== false) {
                $is_html = true;
                break;
            }
        }

        if ($is_html) {
            // HTML email - wrap note in <pre> tag
            $html_note = "<div style='background:#f44336;color:#fff;padding:15px;margin-bottom:20px;border-radius:5px;'>";
            $html_note .= "<strong>⚠️ TEST EMAIL REDIRECT - {$env_label} ENVIRONMENT ⚠️</strong><br><br>";
            $html_note .= "<strong>Original Recipient(s):</strong> {$original_to}<br>";
            $html_note .= "<strong>Redirected To:</strong> {$test_email}<br>";
            $html_note .= "<strong>Environment:</strong> {$env_label}<br>";
            $html_note .= "<strong>Timestamp:</strong> " . current_time('Y-m-d H:i:s');
            $html_note .= "</div>";
            $html_note .= "<hr style='border:2px solid #f44336;margin:20px 0;'>";

            $args['message'] = $html_note . $args['message'];
        } else {
            // Plain text email
            $args['message'] = $original_recipient_note . $args['message'];
        }
    } else {
        // Plain text email (default)
        $args['message'] = $original_recipient_note . $args['message'];
    }

    // Log email redirect for debugging
    if (defined('WP_DEBUG') && WP_DEBUG) {
        error_log(sprintf(
            '[Email Redirect] From: %s, Original To: %s, Redirected To: %s, Subject: %s',
            isset($args['headers']['From']) ? $args['headers']['From'] : 'unknown',
            $original_to,
            $test_email,
            $args['subject']
        ));
    }

    return $args;
}, 999);

/**
 * Add admin notice to remind users email redirect is active
 */
add_action('admin_notices', function() use ($test_email, $wp_env) {
    $env_label = strtoupper($wp_env);
    ?>
    <div class="notice notice-warning is-dismissible">
        <p>
            <strong>⚠️ Email Redirect Active</strong> -
            All emails are being redirected to <code><?php echo esc_html($test_email); ?></code>
            (<?php echo esc_html($env_label); ?> environment)
        </p>
    </div>
    <?php
});

/**
 * Gravity Forms specific email redirect
 *
 * Gravity Forms has its own email sending mechanism, so we hook into it as well
 */
if (class_exists('GFCommon')) {
    add_filter('gform_notification', function($notification, $form, $entry) use ($test_email, $wp_env) {
        // Store original recipient
        $original_to = $notification['to'];

        // Redirect to test email
        $notification['to'] = $test_email;

        // Add prefix to subject
        $env_label = strtoupper($wp_env);
        if (strpos($notification['subject'], "[TEST - ") === false) {
            $notification['subject'] = "[TEST - {$env_label}] " . $notification['subject'];
        }

        // Add note to message
        $redirect_note = "<div style='background:#f44336;color:#fff;padding:15px;margin-bottom:20px;border-radius:5px;'>";
        $redirect_note .= "<strong>⚠️ TEST EMAIL REDIRECT - {$env_label} ENVIRONMENT ⚠️</strong><br><br>";
        $redirect_note .= "<strong>Form:</strong> {$form['title']}<br>";
        $redirect_note .= "<strong>Original Recipient:</strong> {$original_to}<br>";
        $redirect_note .= "<strong>Redirected To:</strong> {$test_email}<br>";
        $redirect_note .= "<strong>Environment:</strong> {$env_label}<br>";
        $redirect_note .= "<strong>Entry ID:</strong> {$entry['id']}";
        $redirect_note .= "</div>";
        $redirect_note .= "<hr style='border:2px solid #f44336;margin:20px 0;'>";

        $notification['message'] = $redirect_note . $notification['message'];

        return $notification;
    }, 999, 3);
}

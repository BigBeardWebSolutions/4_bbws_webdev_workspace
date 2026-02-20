<?php
/**
 * Plugin Name: BBWS Platform - Environment Indicator
 * Description: Visual indicator to show which environment you're working in
 * Version: 1.0.0
 * Author: BBWS Platform Team
 */

/**
 * Display visual environment indicator in non-production environments
 *
 * This helps prevent confusion about which environment you're testing,
 * and reminds testers that emails are redirected and tracking is mocked.
 */

// Only activate in non-production environments
$wp_env = defined('WP_ENV') ? WP_ENV : 'prod';

if (!in_array($wp_env, ['dev', 'sit'])) {
    return; // Don't load in production
}

// Get test email from wp-config.php or use default
$test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : 'tebogo@bigbeard.co.za';

// Set environment-specific colors
$env_colors = [
    'dev' => [
        'bg' => '#ff6b6b',
        'border' => '#ff5252'
    ],
    'sit' => [
        'bg' => '#ffa726',
        'border' => '#ff9800'
    ]
];

$colors = isset($env_colors[$wp_env]) ? $env_colors[$wp_env] : $env_colors['dev'];

/**
 * Frontend environment banner (sticky footer)
 */
add_action('wp_footer', function() use ($wp_env, $test_email, $colors) {
    $env_label = strtoupper($wp_env);
    ?>
    <div id="bbws-env-indicator" style="
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: <?php echo $colors['bg']; ?>;
        color: #fff;
        text-align: center;
        padding: 12px 20px;
        font-weight: bold;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
        font-size: 13px;
        z-index: 999999;
        border-top: 3px solid <?php echo $colors['border']; ?>;
        box-shadow: 0 -2px 10px rgba(0,0,0,0.1);
        line-height: 1.6;
    ">
        <div style="max-width: 1200px; margin: 0 auto;">
            <span style="font-size: 16px;">🚧</span>
            <strong><?php echo $env_label; ?> ENVIRONMENT</strong>
            <span style="font-size: 16px;">🚧</span>
            <br>
            <span style="font-size: 11px; opacity: 0.9;">
                Testing Mode Active
                • Emails → <?php echo esc_html($test_email); ?>
                • Analytics Mocked
                • Not Production Data
            </span>
        </div>
    </div>

    <script>
        // Adjust page padding to account for fixed banner
        document.addEventListener('DOMContentLoaded', function() {
            const indicator = document.getElementById('bbws-env-indicator');
            if (indicator) {
                const height = indicator.offsetHeight;
                document.body.style.paddingBottom = height + 'px';
            }
        });

        // Make banner dismissible (stores in sessionStorage)
        const indicator = document.getElementById('bbws-env-indicator');
        if (indicator && sessionStorage.getItem('bbws_env_indicator_dismissed') === 'true') {
            indicator.style.display = 'none';
            document.body.style.paddingBottom = '0';
        }

        // Add dismiss button on click
        indicator.addEventListener('click', function() {
            this.style.opacity = '0';
            setTimeout(() => {
                this.style.display = 'none';
                document.body.style.paddingBottom = '0';
                sessionStorage.setItem('bbws_env_indicator_dismissed', 'true');
            }, 300);
        });

        indicator.style.transition = 'opacity 0.3s ease';
        indicator.style.cursor = 'pointer';
        indicator.title = 'Click to dismiss';
    </script>
    <?php
}, 999);

/**
 * Admin bar environment indicator
 */
add_action('admin_bar_menu', function($wp_admin_bar) use ($wp_env, $colors) {
    $env_label = strtoupper($wp_env);

    $wp_admin_bar->add_node([
        'id' => 'bbws-environment-indicator',
        'title' => '🚧 ' . $env_label . ' ENVIRONMENT',
        'href' => '#',
        'meta' => [
            'html' => '<style>
                #wp-admin-bar-bbws-environment-indicator > .ab-item {
                    background: ' . $colors['bg'] . ' !important;
                    color: #fff !important;
                    font-weight: bold !important;
                }
                #wp-admin-bar-bbws-environment-indicator > .ab-item:hover {
                    background: ' . $colors['border'] . ' !important;
                }
            </style>'
        ]
    ]);

    // Add submenu with environment info
    $wp_admin_bar->add_node([
        'parent' => 'bbws-environment-indicator',
        'id' => 'bbws-env-info',
        'title' => '<strong>Environment Information</strong>',
        'href' => false,
    ]);

    $wp_admin_bar->add_node([
        'parent' => 'bbws-environment-indicator',
        'id' => 'bbws-env-name',
        'title' => 'Environment: ' . $env_label,
        'href' => false,
    ]);

    $test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : 'tebogo@bigbeard.co.za';
    $wp_admin_bar->add_node([
        'parent' => 'bbws-environment-indicator',
        'id' => 'bbws-env-email',
        'title' => 'Test Email: ' . $test_email,
        'href' => false,
    ]);

    $wp_admin_bar->add_node([
        'parent' => 'bbws-environment-indicator',
        'id' => 'bbws-env-tracking',
        'title' => 'Tracking: Mocked',
        'href' => false,
    ]);
}, 999);

/**
 * Admin dashboard widget with environment information
 */
add_action('wp_dashboard_setup', function() use ($wp_env) {
    wp_add_dashboard_widget(
        'bbws_environment_widget',
        '🚧 Environment Information',
        function() use ($wp_env) {
            $env_label = strtoupper($wp_env);
            $test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : 'tebogo@bigbeard.co.za';
            $tenant_name = defined('TENANT_NAME') ? TENANT_NAME : 'unknown';

            $colors = [
                'dev' => '#ff6b6b',
                'sit' => '#ffa726'
            ];

            $color = isset($colors[$wp_env]) ? $colors[$wp_env] : $colors['dev'];
            ?>
            <div style="background: <?php echo $color; ?>; color: #fff; padding: 20px; border-radius: 5px; margin: -12px -12px 15px -12px;">
                <h3 style="margin: 0 0 10px 0; color: #fff; font-size: 18px;">
                    <?php echo $env_label; ?> ENVIRONMENT
                </h3>
                <p style="margin: 0; opacity: 0.9;">
                    You are currently working in a test environment
                </p>
            </div>

            <table style="width: 100%; border-collapse: collapse;">
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 10px 0; font-weight: bold;">Environment:</td>
                    <td style="padding: 10px 0;"><?php echo $env_label; ?></td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 10px 0; font-weight: bold;">Email Redirect:</td>
                    <td style="padding: 10px 0;"><code><?php echo esc_html($test_email); ?></code></td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 10px 0; font-weight: bold;">Tracking Scripts:</td>
                    <td style="padding: 10px 0;">Mocked (GA, FB Pixel disabled)</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 10px 0; font-weight: bold;">WP_ENV Constant:</td>
                    <td style="padding: 10px 0;"><code><?php echo $wp_env; ?></code></td>
                </tr>
                <tr>
                    <td style="padding: 10px 0; font-weight: bold;">WordPress URL:</td>
                    <td style="padding: 10px 0;"><?php echo home_url(); ?></td>
                </tr>
            </table>

            <div style="background: #f0f0f1; padding: 15px; margin-top: 15px; border-left: 4px solid <?php echo $color; ?>;">
                <strong>⚠️ Important Reminders:</strong>
                <ul style="margin: 10px 0 0 0; padding-left: 20px;">
                    <li>All emails are redirected to the test address above</li>
                    <li>Analytics tracking is disabled - no production data affected</li>
                    <li>This is NOT the production site</li>
                    <li>Changes made here do NOT affect the live site</li>
                </ul>
            </div>
            <?php
        }
    );
});

/**
 * Add environment indicator to login page
 */
add_action('login_head', function() use ($wp_env, $colors) {
    $env_label = strtoupper($wp_env);
    ?>
    <style>
        body.login {
            border-top: 5px solid <?php echo $colors['bg']; ?> !important;
        }
    </style>
    <div style="
        background: <?php echo $colors['bg']; ?>;
        color: #fff;
        text-align: center;
        padding: 15px;
        font-weight: bold;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
        margin: -50px 0 20px 0;
    ">
        🚧 <?php echo $env_label; ?> ENVIRONMENT 🚧
        <br>
        <small style="font-size: 11px; opacity: 0.9;">Testing environment - not production</small>
    </div>
    <?php
});

/**
 * Add meta tag to prevent indexing in search engines
 */
add_action('wp_head', function() {
    echo '<meta name="robots" content="noindex, nofollow">' . "\n";
    echo '<!-- BBWS Platform: Non-production environment -->' . "\n";
}, 1);

/**
 * Disable XML-RPC in non-production (security)
 */
add_filter('xmlrpc_enabled', '__return_false');

/**
 * Log environment startup
 */
if (defined('WP_DEBUG') && WP_DEBUG) {
    error_log(sprintf(
        '[BBWS Platform] Environment indicator loaded: %s environment',
        strtoupper($wp_env)
    ));
}

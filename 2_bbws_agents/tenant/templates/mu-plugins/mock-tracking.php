<?php
/**
 * Plugin Name: BBWS Platform - Mock Tracking Scripts
 * Description: Disables/mocks analytics and tracking scripts in non-production environments
 * Version: 1.0.0
 * Author: BBWS Platform Team
 */

/**
 * Prevent tracking scripts from sending data to production analytics in test environments
 *
 * This includes:
 * - Google Analytics (GA4, Universal Analytics)
 * - Facebook Pixel
 * - Google Tag Manager
 * - Other third-party tracking
 */

// Only activate in non-production environments
$wp_env = defined('WP_ENV') ? WP_ENV : 'prod';

if (!in_array($wp_env, ['dev', 'sit'])) {
    return; // Don't load in production
}

/**
 * Mock Google Analytics tracking
 *
 * Replaces gtag() and ga() calls with console.log() to prevent data from reaching Google Analytics
 */
add_filter('wpheaderandfooter_header_code', function($code) use ($wp_env) {
    $env_label = strtoupper($wp_env);

    // Replace Google Analytics 4 (gtag.js) with console logging
    $code = preg_replace(
        "/gtag\(/",
        "console.log('[{$env_label} - GA4 MOCKED] gtag',",
        $code
    );

    // Replace Universal Analytics (analytics.js) with console logging
    $code = preg_replace(
        "/ga\(/",
        "console.log('[{$env_label} - GA MOCKED] ga',",
        $code
    );

    // Replace Google Analytics measurement IDs with dummy IDs
    $code = preg_replace(
        "/G-[A-Z0-9]+/",
        "G-TESTMODE-{$env_label}",
        $code
    );

    $code = preg_replace(
        "/UA-[0-9]+-[0-9]+/",
        "UA-000000-00",
        $code
    );

    return $code;
}, 999);

/**
 * Mock Facebook Pixel tracking
 *
 * Replaces fbq() calls with console.log() to prevent data from reaching Facebook
 */
add_filter('wpheaderandfooter_header_code', function($code) use ($wp_env) {
    $env_label = strtoupper($wp_env);

    // Replace Facebook Pixel fbq() with console logging
    $code = preg_replace(
        "/fbq\(/",
        "console.log('[{$env_label} - FB PIXEL MOCKED] fbq',",
        $code
    );

    return $code;
}, 999);

add_filter('wpheaderandfooter_footer_code', function($code) use ($wp_env) {
    $env_label = strtoupper($wp_env);

    // Replace Facebook Pixel in footer as well
    $code = preg_replace(
        "/fbq\(/",
        "console.log('[{$env_label} - FB PIXEL MOCKED] fbq',",
        $code
    );

    return $code;
}, 999);

/**
 * Mock Google Tag Manager
 *
 * Prevents GTM from loading or replaces with console logging
 */
add_filter('wpheaderandfooter_header_code', function($code) use ($wp_env) {
    $env_label = strtoupper($wp_env);

    // Replace Google Tag Manager with console logging
    $code = preg_replace(
        "/googletagmanager\.com\/gtm\.js/",
        "# Google Tag Manager disabled in {$env_label}",
        $code
    );

    // Replace GTM-XXXX with dummy ID
    $code = preg_replace(
        "/GTM-[A-Z0-9]+/",
        "GTM-TESTMODE",
        $code
    );

    return $code;
}, 999);

/**
 * Disable tracking scripts via WP Headers and Footers plugin
 *
 * Completely disables the plugin in non-production if needed
 */
add_filter('wpheaderandfooter_disable_frontend', function() use ($wp_env) {
    // Uncomment to completely disable all header/footer injections
    // return in_array($wp_env, ['dev', 'sit']);

    // By default, we mock the scripts (above) rather than completely disabling
    return false;
});

/**
 * Intercept external HTTP requests to tracking services
 *
 * This catches any server-side tracking calls (e.g., Google Analytics Measurement Protocol)
 */
add_filter('pre_http_request', function($preempt, $args, $url) use ($wp_env) {
    $env_label = strtoupper($wp_env);

    // List of tracking domains to block
    $blocked_domains = [
        'google-analytics.com',
        'googletagmanager.com',
        'facebook.com/tr',
        'facebook.net',
        'connect.facebook.net',
        'doubleclick.net',
        'analytics.google.com',
        'stats.wp.com',
    ];

    foreach ($blocked_domains as $domain) {
        if (strpos($url, $domain) !== false) {
            // Log the blocked request
            if (defined('WP_DEBUG') && WP_DEBUG) {
                error_log("[{$env_label}] Blocked tracking request to: {$url}");
            }

            // Return mock response to prevent actual HTTP request
            return [
                'response' => [
                    'code' => 200,
                    'message' => 'OK'
                ],
                'body' => json_encode([
                    'status' => 'test_mode',
                    'message' => "Tracking request blocked in {$env_label} environment",
                    'url' => $url
                ]),
                'headers' => [
                    'content-type' => 'application/json'
                ]
            ];
        }
    }

    return $preempt; // Allow other requests
}, 10, 3);

/**
 * Add admin notice to indicate tracking is mocked
 */
add_action('admin_notices', function() use ($wp_env) {
    $env_label = strtoupper($wp_env);
    ?>
    <div class="notice notice-info is-dismissible">
        <p>
            <strong>📊 Tracking Scripts Mocked</strong> -
            Analytics and tracking scripts are disabled in <?php echo esc_html($env_label); ?> environment.
            No data is being sent to Google Analytics, Facebook Pixel, or other tracking services.
        </p>
    </div>
    <?php
});

/**
 * Add console message to frontend for developers
 */
add_action('wp_footer', function() use ($wp_env) {
    $env_label = strtoupper($wp_env);
    ?>
    <script>
        console.log('%c🚧 <?php echo $env_label; ?> ENVIRONMENT - TRACKING MOCKED 🚧',
            'background: #ff9800; color: #fff; padding: 10px; font-size: 14px; font-weight: bold;');
        console.log('%cAll analytics and tracking scripts are mocked. No data is sent to production services.',
            'color: #ff9800; font-size: 12px;');
        console.log('%cMocked services: Google Analytics, Facebook Pixel, Google Tag Manager',
            'color: #999; font-size: 11px;');
    </script>
    <?php
}, 999);

<?php
/**
 * Plugin Name: Force HTTPS for CloudFront/ALB Architecture
 * Description: Ensures WordPress recognizes HTTPS when behind CloudFront/ALB
 * Version: 1.0
 * Author: BigBeard Web Solutions
 *
 * PURPOSE:
 *   When WordPress runs behind CloudFront → ALB → ECS, the container receives
 *   HTTP requests even though the user accessed via HTTPS. This plugin forces
 *   WordPress to recognize HTTPS, preventing redirect loops.
 *
 * HOW IT WORKS:
 *   1. Checks X-Forwarded-Proto header (sent by CloudFront/ALB)
 *   2. Sets $_SERVER['HTTPS'] = 'on' if proto is https
 *   3. Runs as MU-plugin (loads before all other plugins)
 *   4. Disables other SSL plugins' redirect behavior
 *
 * INSTALLATION:
 *   Copy to: wp-content/mu-plugins/force-https-cloudfront.php
 *   (Create mu-plugins folder if it doesn't exist)
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// ============================================================================
// FORCE HTTPS RECOGNITION
// ============================================================================

/**
 * Force WordPress to recognize HTTPS from CloudFront/ALB
 * This runs very early, before WordPress core checks HTTPS
 */
function bbws_force_https_recognition() {
    // Check if request came through CloudFront/ALB with HTTPS
    $is_https = false;

    // Method 1: X-Forwarded-Proto header (CloudFront/ALB)
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO'])) {
        $is_https = (strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https');
    }

    // Method 2: CloudFront-Forwarded-Proto header
    if (!$is_https && isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'])) {
        $is_https = (strtolower($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) === 'https');
    }

    // Method 3: X-Forwarded-SSL header
    if (!$is_https && isset($_SERVER['HTTP_X_FORWARDED_SSL'])) {
        $is_https = (strtolower($_SERVER['HTTP_X_FORWARDED_SSL']) === 'on');
    }

    // Method 4: Already HTTPS
    if (!$is_https && isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
        $is_https = true;
    }

    // Force HTTPS recognition
    if ($is_https) {
        $_SERVER['HTTPS'] = 'on';
        $_SERVER['SERVER_PORT'] = 443;
    }
}

// Run immediately (before WordPress loads)
bbws_force_https_recognition();

// ============================================================================
// DISABLE SSL PLUGIN REDIRECTS
// ============================================================================

/**
 * Prevent Really Simple SSL from doing redirects
 */
add_filter('rsssl_ssl_enabled', '__return_false', 999);
add_filter('rlrsssl_ssl_enabled', '__return_false', 999);

/**
 * Prevent WordPress HTTPS plugin redirects
 */
add_filter('wordpress_https_ssl_enabled', '__return_false', 999);

/**
 * Prevent iThemes Security SSL redirects
 */
add_filter('itsec_ssl_enabled', '__return_false', 999);

/**
 * Remove any redirect actions from SSL plugins
 */
function bbws_remove_ssl_redirects() {
    // Really Simple SSL
    remove_action('template_redirect', 'rsssl_redirect_to_ssl', 1);
    remove_action('wp_loaded', 'rsssl_redirect_to_ssl', 1);

    // WordPress HTTPS
    remove_action('template_redirect', 'wordpress_https_redirect', 1);

    // Generic SSL redirect removal
    remove_action('template_redirect', 'ssl_redirect', 1);
    remove_action('init', 'ssl_redirect', 1);
}
add_action('plugins_loaded', 'bbws_remove_ssl_redirects', 1);
add_action('init', 'bbws_remove_ssl_redirects', 1);

// ============================================================================
// ENSURE HTTPS IN URLs
// ============================================================================

/**
 * Force HTTPS in site URLs
 */
function bbws_force_https_urls($url) {
    if (is_ssl() || (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on')) {
        $url = str_replace('http://', 'https://', $url);
    }
    return $url;
}
add_filter('site_url', 'bbws_force_https_urls', 999);
add_filter('home_url', 'bbws_force_https_urls', 999);
add_filter('content_url', 'bbws_force_https_urls', 999);
add_filter('plugins_url', 'bbws_force_https_urls', 999);
add_filter('wp_get_attachment_url', 'bbws_force_https_urls', 999);

/**
 * Force HTTPS in content
 */
function bbws_force_https_content($content) {
    if (is_ssl() || (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on')) {
        // Get site domain
        $site_url = get_site_url();
        $domain = parse_url($site_url, PHP_URL_HOST);

        if ($domain) {
            // Replace http:// with https:// for this domain only
            $content = str_replace("http://{$domain}", "https://{$domain}", $content);
        }
    }
    return $content;
}
add_filter('the_content', 'bbws_force_https_content', 999);
add_filter('widget_text', 'bbws_force_https_content', 999);

// ============================================================================
// SECURITY: DISABLE WORDFENCE BLOCKING (OPTIONAL)
// ============================================================================

/**
 * Prevent Wordfence from blocking CloudFront/ALB IPs
 * These are internal AWS IPs that should be trusted
 */
function bbws_wordfence_trust_cloudfront($is_trusted, $ip) {
    // AWS CloudFront IP ranges start with these
    $cloudfront_ranges = [
        '13.',
        '52.',
        '54.',
        '99.',
        '143.',
        '205.',
    ];

    foreach ($cloudfront_ranges as $range) {
        if (strpos($ip, $range) === 0) {
            return true;
        }
    }

    return $is_trusted;
}
add_filter('wordfence_is_trusted_ip', 'bbws_wordfence_trust_cloudfront', 10, 2);

// ============================================================================
// ADMIN NOTICE (Development/Staging Only)
// ============================================================================

/**
 * Show notice that HTTPS forcing is active
 */
function bbws_https_admin_notice() {
    if (!current_user_can('manage_options')) {
        return;
    }

    $env = defined('WP_ENV') ? WP_ENV : 'unknown';
    if ($env === 'prod') {
        return; // Don't show in production
    }

    echo '<div class="notice notice-info is-dismissible">';
    echo '<p><strong>BBWS CloudFront HTTPS:</strong> ';
    echo 'HTTPS forcing is active. ';
    echo 'X-Forwarded-Proto: ' . esc_html($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? 'not set') . ' | ';
    echo '$_SERVER[HTTPS]: ' . esc_html($_SERVER['HTTPS'] ?? 'not set');
    echo '</p></div>';
}
add_action('admin_notices', 'bbws_https_admin_notice');

// ============================================================================
// DEBUG LOGGING (Uncomment for troubleshooting)
// ============================================================================

/*
function bbws_debug_https() {
    error_log('BBWS HTTPS Debug:');
    error_log('  X-Forwarded-Proto: ' . ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? 'not set'));
    error_log('  $_SERVER[HTTPS]: ' . ($_SERVER['HTTPS'] ?? 'not set'));
    error_log('  is_ssl(): ' . (is_ssl() ? 'true' : 'false'));
    error_log('  REQUEST_URI: ' . ($_SERVER['REQUEST_URI'] ?? 'not set'));
}
add_action('init', 'bbws_debug_https');
*/

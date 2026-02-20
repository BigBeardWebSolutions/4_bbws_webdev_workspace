<?php
/**
 * Plugin Name: BBWS Platform - Force HTTPS
 * Description: Forces all WordPress URLs to use HTTPS (for CloudFront/ALB setup)
 * Version: 1.0.0
 * Author: BBWS Platform Team
 */

// Suppress PHP deprecation warnings (PHP 8.x compatibility)
error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT);
ini_set('display_errors', '0');

// Force HTTPS detection for WordPress
$_SERVER["HTTPS"] = "on";
$_SERVER["SERVER_PORT"] = 443;

/**
 * Filter all WordPress URL generation to force HTTPS
 *
 * This is necessary when CloudFront terminates SSL and sends HTTP to the origin (ALB).
 * Without these filters, WordPress would detect HTTP and generate HTTP URLs for assets,
 * causing mixed content warnings in browsers.
 */

// Force HTTPS in site URL (from database)
add_filter("option_siteurl", function($url) {
    return str_replace("http://", "https://", $url);
});

// Force HTTPS in home URL (from database)
add_filter("option_home", function($url) {
    return str_replace("http://", "https://", $url);
});

// Force HTTPS in wp-content URL
add_filter("content_url", function($url) {
    return str_replace("http://", "https://", $url);
});

// Force HTTPS in plugins URL
add_filter("plugins_url", function($url) {
    return str_replace("http://", "https://", $url);
});

// Force HTTPS in JavaScript file URLs
add_filter("script_loader_src", function($src) {
    return str_replace("http://", "https://", $src);
});

// Force HTTPS in CSS file URLs
add_filter("style_loader_src", function($src) {
    return str_replace("http://", "https://", $src);
});

// Force HTTPS in theme directory URL
add_filter("theme_root_uri", function($url) {
    return str_replace("http://", "https://", $url);
});

// Force HTTPS in upload directory URL
add_filter("upload_dir", function($uploads) {
    $uploads['url'] = str_replace("http://", "https://", $uploads['url']);
    $uploads['baseurl'] = str_replace("http://", "https://", $uploads['baseurl']);
    return $uploads;
});

<?php
/**
 * Custom WordPress configuration for path-based multi-tenancy
 * This file is prepended to the standard wp-config.php
 */

// Get the tenant path from request URI
$request_uri = $_SERVER['REQUEST_URI'] ?? '';
$tenant_path = '';

// Extract tenant ID from path (e.g., /tenant-1/... -> tenant-1)
if (preg_match('#^/([^/]+)/#', $request_uri, $matches)) {
    $tenant_path = '/' . $matches[1];
}

// Set WordPress URLs to include the tenant path
$site_url = 'http://' . $_SERVER['HTTP_HOST'] . $tenant_path;

define('WP_HOME', $site_url);
define('WP_SITEURL', $site_url);

// Force WordPress to handle the path correctly
$_SERVER['REQUEST_URI'] = preg_replace('#^' . preg_quote($tenant_path, '#') . '#', '', $_SERVER['REQUEST_URI']);
if (empty($_SERVER['REQUEST_URI'])) {
    $_SERVER['REQUEST_URI'] = '/';
}

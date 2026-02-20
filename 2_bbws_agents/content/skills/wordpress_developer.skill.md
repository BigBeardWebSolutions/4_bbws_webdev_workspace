# WordPress Developer Skill

**Version**: 1.0
**Created**: 2025-12-17
**Purpose**: Advanced WordPress development beyond content management - custom themes, plugins, migrations, and deep technical troubleshooting

---

## Skill Identity

**Name**: WordPress Developer
**Type**: Technical development skill
**Domain**: WordPress core development, custom themes, plugins, migrations, performance optimization, security hardening, and complex troubleshooting

---

## Purpose

The WordPress Developer skill extends the Content Manager agent with advanced development capabilities. While the base agent focuses on content operations and plugin configuration, this skill handles:

- **Custom Theme Development**: Child themes, template hierarchy, custom page templates
- **Custom Plugin Development**: Hooks, filters, custom post types, taxonomies
- **WordPress Migrations**: Complete site migrations with domain changes, SSL transitions, database transformations
- **WP-CLI Mastery**: Bulk operations, automation scripts, maintenance tasks
- **Performance Engineering**: Advanced caching strategies, database optimization, query performance
- **Security Architecture**: File permissions, user role engineering, vulnerability analysis
- **API Integration**: REST API, GraphQL, third-party service integration
- **Multi-Site Configuration**: Network setup, domain mapping, site management
- **Gutenberg Development**: Custom blocks, block patterns, full-site editing

**Value Provided**:
- **Technical Depth**: Handle challenges beyond standard plugin configuration
- **Migration Expertise**: Safely move sites between hosts, domains, and environments
- **Performance Optimization**: Achieve lighthouse scores >90 and Core Web Vitals compliance
- **Security Hardening**: Implement defense-in-depth security architecture
- **Development Automation**: WP-CLI scripts for repetitive tasks
- **Custom Solutions**: Build bespoke functionality when plugins don't exist

---

## Behavioral Approach

### Patient Guidance

**Multi-Step Workflows**:
- Break complex development tasks into clear phases
- Provide checkpoints after each major step
- Wait for user confirmation before proceeding to next phase
- Offer to pause and resume at any time

**Example Workflow - Theme Migration**:
```
Phase 1: Pre-Migration Analysis (30 min)
  ✓ Document current theme configuration
  ✓ Identify custom code and dependencies
  ✓ Create backup strategy
  [CHECKPOINT: Review analysis report]

Phase 2: Development Environment Setup (20 min)
  ✓ Clone production to staging
  ✓ Install new theme
  ✓ Configure child theme
  [CHECKPOINT: Verify staging environment]

Phase 3: Migration Execution (60 min)
  ✓ Migrate content structure
  ✓ Update templates
  ✓ Test all pages
  [CHECKPOINT: User acceptance testing]

Phase 4: Production Deployment (30 min)
  ✓ Final backup
  ✓ Deploy to production
  ✓ Verification testing
  [CHECKPOINT: Go-live confirmation]
```

### Courteous Interaction

**Professional Communication**:
- Use clear, jargon-free language (explain technical terms when needed)
- Acknowledge user's expertise level and adapt accordingly
- Never condescending - treat users as collaborators
- Celebrate milestones: "Great! Theme activated successfully. Ready for customization?"

**Example Interactions**:
```
❌ Bad: "You need to SSH into the server and run these commands."
✅ Good: "I'll guide you through connecting to your server. Have you used SSH before,
         or would you like a quick overview first?"

❌ Bad: "That plugin is poorly coded and causes performance issues."
✅ Good: "I've analyzed the plugin and found some optimization opportunities.
         Would you like me to explain what's causing the slowdown?"
```

### Gentle Guidance

**Learning-Focused Approach**:
- Explain *why* we're doing something, not just *how*
- Provide context for decisions
- Offer alternatives when multiple valid approaches exist
- Support skill development, not just task completion

**Decision Support**:
```
"For this migration, we have three approaches:

Option 1: All-in-One WP Migration Plugin
  Pros: Simple, one-click migration
  Cons: File size limits, less control
  Best for: Small sites (<500MB), quick migrations

Option 2: Manual Database Export + File Sync
  Pros: Complete control, no size limits
  Cons: More technical, requires WP-CLI knowledge
  Best for: Large sites, custom configurations

Option 3: WP-CLI with Search-Replace
  Pros: Automation, repeatable, scriptable
  Cons: Requires command-line comfort
  Best for: Multiple migrations, development workflows

Which approach feels right for your situation?"
```

### Technical Depth

**Advanced Troubleshooting**:
- Root cause analysis, not just symptom treatment
- Explain complex technical concepts clearly
- Provide multiple resolution strategies
- Reference WordPress Codex, Stack Exchange, and documentation

**Example - White Screen of Death**:
```
"I've identified the WSOD root cause through systematic analysis:

Step 1: Enabled WP_DEBUG
  Result: Fatal error in functions.php line 127

Step 2: Analyzed Error
  Issue: Deprecated function 'create_function()' (removed in PHP 8.0)

Step 3: Identified Resolution Paths
  Option A: Update theme to PHP 8.0 compatible version
  Option B: Refactor function to use anonymous function
  Option C: Downgrade PHP to 7.4 (temporary, not recommended)

Recommendation: Option A (theme update) with B as backup if theme is abandoned.

Would you like me to check if a theme update is available?"
```

---

## Core Capabilities

### 1. Custom Theme Development

#### Child Theme Creation
- Generate child theme structure (style.css, functions.php)
- Enqueue parent theme styles properly
- Override parent templates selectively
- Implement custom page templates
- Add theme support features (menus, widgets, post-thumbnails)

**Workflow Example**:
```php
// Child Theme Functions.php Template
<?php
/**
 * Theme Name: Big Beard Client Child
 * Description: Custom child theme for [Client Name]
 * Template: hello-elementor
 * Version: 1.0.0
 */

// Enqueue parent and child theme styles
function bbws_enqueue_styles() {
    wp_enqueue_style('parent-style',
        get_template_directory_uri() . '/style.css'
    );
    wp_enqueue_style('child-style',
        get_stylesheet_directory_uri() . '/style.css',
        array('parent-style'),
        wp_get_theme()->get('Version')
    );
}
add_action('wp_enqueue_scripts', 'bbws_enqueue_styles');

// Add theme support
function bbws_theme_setup() {
    add_theme_support('post-thumbnails');
    add_theme_support('custom-logo');
    register_nav_menus(array(
        'primary' => __('Primary Menu', 'bbws'),
        'footer' => __('Footer Menu', 'bbws')
    ));
}
add_action('after_setup_theme', 'bbws_theme_setup');
```

#### Template Hierarchy Mastery
- Understand WordPress template hierarchy
- Create custom templates (single-{post-type}.php, page-{slug}.php)
- Implement template parts for reusability
- Use get_template_part() effectively
- Override specific templates in child theme

#### Big Beard Design Integration
Based on Big Beard Web Design analysis:

**Typography System**:
```css
/* Big Beard Typography Hierarchy */
h1, .hero-heading {
    font-size: 45px;
    line-height: 1.2em;
    font-weight: 800;
}

@media (max-width: 850px) {
    h1, .hero-heading {
        font-size: 34px;
    }
}

body {
    font-size: 20px;
    line-height: 1.3em;
    font-family: 'Inter', sans-serif;
}

@media (max-width: 500px) {
    body {
        font-size: 18px;
    }
}
```

**Animation Patterns**:
```css
/* Signature Big Beard Animations */
.text-btn a {
    transition: letter-spacing 0.3s ease-in-out;
}

.text-btn a:hover {
    letter-spacing: 2px;
}

.fadeIn {
    animation: fadeIn 0.6s ease-in-out;
}

.slideInLeft {
    animation: slideInLeft 0.8s ease-out;
}

/* Staggered Animation Delays */
.animated-element:nth-child(1) { animation-delay: 200ms; }
.animated-element:nth-child(2) { animation-delay: 400ms; }
.animated-element:nth-child(3) { animation-delay: 600ms; }
```

**CTA Design Pattern**:
```css
/* Big Beard Signature CTA Style */
.text-btn a {
    background-color: transparent;
    text-transform: uppercase;
    padding-bottom: 2px;
    border-bottom: 1px solid currentColor;
    border-radius: 0px;
    font-weight: 600;
    text-decoration: none;
    display: inline-block;
}
```

### 2. Custom Plugin Development

#### Plugin Structure
- Create plugin header with proper metadata
- Organize code (classes, includes, assets)
- Implement activation/deactivation hooks
- Use WordPress coding standards
- Namespace code to avoid conflicts

**Basic Plugin Template**:
```php
<?php
/**
 * Plugin Name: BBWS Custom Functionality
 * Description: Custom features for BBWS clients
 * Version: 1.0.0
 * Author: Big Beard Web Services
 * License: GPL v2 or later
 */

// Prevent direct access
if (!defined('ABSPATH')) exit;

// Plugin activation
register_activation_hook(__FILE__, 'bbws_plugin_activate');
function bbws_plugin_activate() {
    // Activation tasks (create tables, set defaults)
    flush_rewrite_rules();
}

// Plugin deactivation
register_deactivation_hook(__FILE__, 'bbws_plugin_deactivate');
function bbws_plugin_deactivate() {
    // Cleanup tasks
    flush_rewrite_rules();
}
```

#### Custom Post Types & Taxonomies
- Register custom post types (projects, testimonials, products)
- Create custom taxonomies
- Configure post type features and UI
- Set up rewrite rules and permalinks
- Add custom meta boxes

**Example - Portfolio Post Type**:
```php
function bbws_register_portfolio_post_type() {
    $args = array(
        'public' => true,
        'label'  => 'Portfolio',
        'labels' => array(
            'name' => 'Portfolio Items',
            'singular_name' => 'Portfolio Item',
            'add_new_item' => 'Add New Portfolio Item'
        ),
        'supports' => array('title', 'editor', 'thumbnail', 'excerpt'),
        'has_archive' => true,
        'rewrite' => array('slug' => 'portfolio'),
        'show_in_rest' => true, // Gutenberg support
        'menu_icon' => 'dashicons-portfolio'
    );
    register_post_type('portfolio', $args);
}
add_action('init', 'bbws_register_portfolio_post_type');
```

#### Hooks & Filters
- Use actions for executing code at specific points
- Use filters for modifying data
- Create custom hooks for extensibility
- Understand hook priority and arguments
- Remove/modify existing hooks when needed

**Common Hook Patterns**:
```php
// Modify excerpt length
add_filter('excerpt_length', function($length) {
    return 20;
}, 999);

// Add custom body classes
add_filter('body_class', function($classes) {
    if (is_page('about')) {
        $classes[] = 'about-page';
    }
    return $classes;
});

// Enqueue scripts conditionally
add_action('wp_enqueue_scripts', function() {
    if (is_singular('portfolio')) {
        wp_enqueue_script('portfolio-gallery',
            get_stylesheet_directory_uri() . '/js/gallery.js',
            array('jquery'),
            '1.0.0',
            true
        );
    }
});
```

### 3. WordPress Migrations

#### Pre-Migration Planning
**Checklist**:
- [ ] Document current environment (PHP version, MySQL version, plugins, theme)
- [ ] Identify custom code locations
- [ ] Note email configurations (SMTP settings)
- [ ] List domain/URL occurrences
- [ ] Create comprehensive backup
- [ ] Set up maintenance mode
- [ ] Communicate downtime to stakeholders

#### Database Migration with URL Changes
**WP-CLI Search-Replace Method**:
```bash
# 1. Export database from source
wp db export backup.sql

# 2. Import to destination
wp db import backup.sql

# 3. Search-replace URLs (dry-run first)
wp search-replace 'http://oldsite.com' 'https://newsite.com' --dry-run

# 4. Execute actual replacement
wp search-replace 'http://oldsite.com' 'https://newsite.com'

# 5. Update site URL and home options
wp option update siteurl 'https://newsite.com'
wp option update home 'https://newsite.com'

# 6. Flush permalinks
wp rewrite flush

# 7. Clear all caches
wp cache flush
```

**Manual Database Method**:
```sql
-- Update site URL
UPDATE wp_options SET option_value = 'https://newsite.com'
WHERE option_name IN ('siteurl', 'home');

-- Update post content URLs
UPDATE wp_posts SET post_content =
REPLACE(post_content, 'http://oldsite.com', 'https://newsite.com');

-- Update post GUIDs (careful - usually not recommended)
-- Only if absolutely necessary
UPDATE wp_posts SET guid =
REPLACE(guid, 'http://oldsite.com', 'https://newsite.com');

-- Update meta data
UPDATE wp_postmeta SET meta_value =
REPLACE(meta_value, 'http://oldsite.com', 'https://newsite.com');
```

#### File System Migration
```bash
# Sync files excluding cache and uploads (handle separately)
rsync -avz --exclude='wp-content/cache' \
           --exclude='wp-content/uploads' \
           /source/path/ /destination/path/

# Sync uploads separately with progress
rsync -avzP /source/wp-content/uploads/ /destination/wp-content/uploads/

# Set correct permissions
find /destination/path -type d -exec chmod 755 {} \;
find /destination/path -type f -exec chmod 644 {} \;
chmod 600 /destination/path/wp-config.php
```

#### Post-Migration Verification
**Verification Checklist**:
- [ ] Site loads at new URL
- [ ] Admin dashboard accessible
- [ ] All pages render correctly
- [ ] Images display (check various pages)
- [ ] Forms submit successfully
- [ ] Email sending works (WP Mail SMTP)
- [ ] SSL certificate valid
- [ ] Permalinks working (test various post types)
- [ ] Plugin functionality intact
- [ ] Search functionality works
- [ ] Cache cleared and rebuilt

### 4. WP-CLI Mastery

#### Essential WP-CLI Commands

**Site Management**:
```bash
# Site health check
wp doctor check

# List all users
wp user list

# Create admin user
wp user create newadmin admin@example.com --role=administrator

# Update all plugins
wp plugin update --all

# Install and activate plugin
wp plugin install wordfence --activate

# Search and replace in database
wp search-replace 'old' 'new' --dry-run

# Regenerate thumbnails
wp media regenerate --yes

# Export database
wp db export backup-$(date +%Y%m%d).sql

# Optimize database
wp db optimize

# Check database
wp db check
```

**Content Operations**:
```bash
# List all posts
wp post list --post_type=post --posts_per_page=100

# Delete spam comments in bulk
wp comment delete $(wp comment list --status=spam --format=ids)

# Import content from XML
wp import export.xml --authors=create

# Create test content
wp post generate --count=50

# Update post meta
wp post meta update 123 custom_field 'new value'
```

**Performance & Maintenance**:
```bash
# Clear all caches
wp cache flush
wp transient delete --all

# Verify core files integrity
wp core verify-checksums

# Update WordPress core
wp core update

# Rewrite permalinks
wp rewrite flush

# List all registered image sizes
wp media image-size
```

#### WP-CLI Automation Scripts

**Daily Maintenance Script**:
```bash
#!/bin/bash
# daily-maintenance.sh

SITE_PATH="/var/www/html"
DATE=$(date +%Y%m%d)

cd $SITE_PATH

# Database backup
wp db export backups/db-$DATE.sql

# Delete old backups (keep 7 days)
find backups/ -name "*.sql" -mtime +7 -delete

# Clear transients
wp transient delete --expired

# Optimize database tables
wp db optimize

# Check for plugin updates
wp plugin list --update=available

# Check for theme updates
wp theme list --update=available

# Log completion
echo "$(date): Daily maintenance completed" >> maintenance.log
```

### 5. Performance Optimization

#### Database Optimization

**Query Optimization**:
```php
// ❌ Bad: Multiple queries in loop
foreach ($posts as $post) {
    $meta = get_post_meta($post->ID, 'custom_field', true);
}

// ✅ Good: Single query with update_post_meta_cache
$posts = get_posts(array('posts_per_page' => 100));
update_post_meta_cache(wp_list_pluck($posts, 'ID'));
foreach ($posts as $post) {
    $meta = get_post_meta($post->ID, 'custom_field', true);
}
```

**Database Cleanup**:
```sql
-- Delete post revisions (keep last 5)
DELETE FROM wp_posts WHERE post_type = 'revision';

-- Clean up expired transients
DELETE FROM wp_options WHERE option_name LIKE '_transient_%'
AND option_name NOT LIKE '_transient_timeout_%';

-- Remove orphaned post meta
DELETE pm FROM wp_postmeta pm
LEFT JOIN wp_posts p ON p.ID = pm.post_id
WHERE p.ID IS NULL;

-- Optimize all tables
OPTIMIZE TABLE wp_posts, wp_postmeta, wp_options, wp_comments;
```

#### Caching Strategies

**Object Caching**:
```php
// Cache expensive queries
function bbws_get_featured_posts() {
    $cache_key = 'bbws_featured_posts';
    $posts = wp_cache_get($cache_key);

    if (false === $posts) {
        $posts = get_posts(array(
            'meta_key' => 'featured',
            'meta_value' => '1',
            'posts_per_page' => 10
        ));
        wp_cache_set($cache_key, $posts, '', 3600); // 1 hour
    }

    return $posts;
}
```

**Transients for External API Calls**:
```php
function bbws_get_weather_data() {
    $transient = get_transient('weather_data');

    if (false === $transient) {
        $response = wp_remote_get('https://api.weather.com/data');
        $transient = wp_remote_retrieve_body($response);
        set_transient('weather_data', $transient, 1800); // 30 minutes
    }

    return $transient;
}
```

#### Image Optimization

**Lazy Loading Implementation**:
```php
// Add lazy loading to images
add_filter('wp_get_attachment_image_attributes', function($attr) {
    $attr['loading'] = 'lazy';
    return $attr;
}, 10, 1);
```

**WebP Conversion**:
```bash
# Convert images to WebP (WP-CLI + Imagick)
for img in wp-content/uploads/**/*.jpg; do
    cwebp -q 80 "$img" -o "${img%.jpg}.webp"
done
```

### 6. Security Hardening

#### File Permissions
```bash
# Secure WordPress installation
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod 600 wp-config.php
chown -R www-data:www-data /var/www/html
```

#### wp-config.php Hardening
```php
// Disable file editing
define('DISALLOW_FILE_EDIT', true);

// Limit post revisions
define('WP_POST_REVISIONS', 5);

// Set autosave interval (seconds)
define('AUTOSAVE_INTERVAL', 300);

// Force SSL for admin
define('FORCE_SSL_ADMIN', true);

// Security keys (generate at https://api.wordpress.org/secret-key/1.1/salt/)
define('AUTH_KEY',         'generated-key-here');
define('SECURE_AUTH_KEY',  'generated-key-here');
// ... etc

// Disable debug in production
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
```

#### User Role Management
```php
// Create custom role with specific capabilities
function bbws_create_custom_role() {
    add_role('content_manager', 'Content Manager', array(
        'read' => true,
        'edit_posts' => true,
        'edit_published_posts' => true,
        'publish_posts' => true,
        'delete_posts' => true,
        'upload_files' => true
    ));
}
add_action('init', 'bbws_create_custom_role');

// Add custom capability to existing role
$role = get_role('editor');
$role->add_cap('manage_categories');
```

#### Security Monitoring
```bash
# Check for modified core files
wp core verify-checksums

# List admin users
wp user list --role=administrator

# Scan for malware patterns
grep -r "eval(base64_decode" wp-content/

# Check file permissions
find . -type f -perm 0777

# Review .htaccess for suspicious rules
cat .htaccess
```

### 7. REST API Integration

#### Custom Endpoints
```php
// Register custom REST API endpoint
add_action('rest_api_init', function() {
    register_rest_route('bbws/v1', '/portfolio', array(
        'methods' => 'GET',
        'callback' => 'bbws_get_portfolio_items',
        'permission_callback' => '__return_true'
    ));
});

function bbws_get_portfolio_items($request) {
    $posts = get_posts(array(
        'post_type' => 'portfolio',
        'posts_per_page' => 10
    ));

    $data = array();
    foreach ($posts as $post) {
        $data[] = array(
            'id' => $post->ID,
            'title' => $post->post_title,
            'content' => apply_filters('the_content', $post->post_content),
            'featured_image' => get_the_post_thumbnail_url($post->ID, 'large'),
            'link' => get_permalink($post->ID)
        );
    }

    return new WP_REST_Response($data, 200);
}
```

#### Authentication
```php
// JWT authentication example
add_filter('rest_authentication_errors', function($result) {
    if (!empty($result)) {
        return $result;
    }

    $auth_header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!$auth_header) {
        return new WP_Error('no_auth', 'No authentication provided',
            array('status' => 401));
    }

    // Validate JWT token (requires JWT library)
    $token = str_replace('Bearer ', '', $auth_header);
    // ... validation logic

    return $result;
});
```

### 8. Gutenberg Block Development

#### Custom Block Registration
```javascript
// block.js
import { registerBlockType } from '@wordpress/blocks';
import { RichText } from '@wordpress/block-editor';

registerBlockType('bbws/portfolio-item', {
    title: 'Portfolio Item',
    icon: 'portfolio',
    category: 'common',
    attributes: {
        title: { type: 'string' },
        description: { type: 'string' }
    },

    edit: ({ attributes, setAttributes }) => {
        return (
            <div className="bbws-portfolio-item">
                <RichText
                    tagName="h3"
                    value={attributes.title}
                    onChange={(title) => setAttributes({ title })}
                    placeholder="Portfolio Title"
                />
                <RichText
                    tagName="p"
                    value={attributes.description}
                    onChange={(description) => setAttributes({ description })}
                    placeholder="Description"
                />
            </div>
        );
    },

    save: ({ attributes }) => {
        return (
            <div className="bbws-portfolio-item">
                <RichText.Content tagName="h3" value={attributes.title} />
                <RichText.Content tagName="p" value={attributes.description} />
            </div>
        );
    }
});
```

---

## Troubleshooting Guide

### Complex Issue Resolution

#### Issue: Site Performance Degradation

**Systematic Diagnosis**:
```
Step 1: Identify Symptoms
- Slow page load time (>3 seconds)
- High Time to First Byte (TTFB >600ms)
- Database queries >50 per page

Step 2: Gather Data
wp doctor check --all
wp profile stage --all
Query Monitor plugin analysis

Step 3: Isolate Root Cause
- Check slow queries in Query Monitor
- Analyze PHP memory usage
- Review cache hit ratios
- Inspect external API calls

Step 4: Resolution Strategy
Option A: Query optimization (if database issue)
Option B: Object caching (if repeated queries)
Option C: Plugin replacement (if plugin causing slowdown)
Option D: Server upgrade (if resource exhaustion)

Step 5: Implement and Verify
- Apply fix in staging first
- Measure improvement (before/after)
- Deploy to production with monitoring
```

#### Issue: Plugin Conflict After Update

**Resolution Workflow**:
```bash
# 1. Identify conflicting plugins
wp plugin deactivate --all

# 2. Activate plugins one by one
for plugin in $(wp plugin list --status=inactive --field=name); do
    echo "Testing $plugin"
    wp plugin activate $plugin
    # Test site functionality here
    read -p "Working? (y/n): " response
    if [ "$response" != "y" ]; then
        echo "$plugin is problematic"
        wp plugin deactivate $plugin
        break
    fi
done

# 3. Document conflict
echo "Conflict: $plugin with [other plugin]" >> conflicts.log

# 4. Resolution options
# - Update problematic plugin
# - Replace with alternative
# - Contact plugin developer
# - Implement workaround in child theme
```

---

## Knowledge Base References

### From Big Beard Design Analysis

**Technical Stack**:
- WordPress 6.8+ core
- Elementor Pro 3.31+ for page building
- Hello Elementor 3.4+ (parent theme)
- Child theme for all customizations

**Design Patterns to Implement**:
- Letter-spacing hover effects on CTAs
- Staggered animation delays (200ms, 400ms, 600ms)
- Grayscale hover states for images
- Sticky navigation on scroll
- Generous white space in layouts

**Performance Standards**:
- Lazy loading for all images
- Minified CSS/JS
- WebP image formats
- Selective script loading
- Local font hosting

### From Beautiful Web Design Research

**Performance Metrics to Achieve**:
- Largest Contentful Paint (LCP) < 2.5s
- First Input Delay (FID) < 100ms
- Cumulative Layout Shift (CLS) < 0.1
- Google PageSpeed score ≥ 90

**Accessibility Standards**:
- WCAG 4.5:1 minimum contrast ratio
- Keyboard navigation support
- Screen reader compatibility
- Alt text for all images

---

## Success Criteria

### Development Projects
- ✅ Code follows WordPress coding standards
- ✅ All functionality tested in staging before production
- ✅ Performance metrics maintained or improved
- ✅ Security best practices implemented
- ✅ Documentation created for custom code
- ✅ No PHP errors or warnings
- ✅ Responsive across all devices
- ✅ Accessibility standards met

### Migrations
- ✅ Zero data loss
- ✅ All URLs updated correctly
- ✅ Images and media display properly
- ✅ Forms and integrations functional
- ✅ SSL certificate valid
- ✅ Email delivery working
- ✅ Performance equal or better than source
- ✅ User verification completed

### Performance Optimization
- ✅ Page load time reduced by ≥30%
- ✅ Database query count reduced
- ✅ Cache hit ratio ≥70%
- ✅ Core Web Vitals pass
- ✅ No broken functionality from optimization

---

## Version History

- **v1.0** (2025-12-17): Initial WordPress Developer skill with custom theme development, plugin development, migrations, WP-CLI mastery, performance optimization, security hardening, API integration, and Gutenberg development

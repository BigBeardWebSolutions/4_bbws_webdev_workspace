#!/bin/bash

# Deploy BBWS Platform MU-Plugins to Au Pair Hive DEV
# This script deploys all test environment MU-plugins to the ECS container

CLUSTER="dev-cluster"
TASK_ID="a98986745c97427c95c12b8e85f4c5d7"
CONTAINER="wordpress"
AWS_PROFILE="Tebogo-dev"
AWS_REGION="eu-west-1"

echo "Deploying BBWS Platform MU-Plugins..."
echo "Cluster: $CLUSTER"
echo "Task: $TASK_ID"
echo ""

# Deploy test-email-redirect.php
echo "📧 Deploying test-email-redirect.php..."

aws ecs execute-command \
  --cluster "$CLUSTER" \
  --task "$TASK_ID" \
  --container "$CONTAINER" \
  --command "bash -c 'cat > /var/www/html/wp-content/mu-plugins/bbws-platform/test-email-redirect.php << '\'EOF'\'
<?php
/**
 * Plugin Name: BBWS Platform - Test Email Redirect
 * Description: Redirects all WordPress emails to test address in non-production environments
 * Version: 1.0.0
 */

\$wp_env = defined(\"WP_ENV\") ? WP_ENV : \"prod\";

if (!in_array(\$wp_env, [\"dev\", \"sit\"])) {
    return;
}

\$test_email = defined(\"TEST_EMAIL_REDIRECT\") ? TEST_EMAIL_REDIRECT : \"tebogo@bigbeard.co.za\";

add_filter(\"wp_mail\", function(\$args) use (\$test_email, \$wp_env) {
    \$original_to = is_array(\$args[\"to\"]) ? implode(\", \", \$args[\"to\"]) : \$args[\"to\"];
    \$args[\"to\"] = \$test_email;

    \$env_label = strtoupper(\$wp_env);
    if (strpos(\$args[\"subject\"], \"[TEST - \") === false) {
        \$args[\"subject\"] = \"[TEST - {\$env_label}] \" . \$args[\"subject\"];
    }

    \$note = \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\";
    \$note .= \"TEST EMAIL REDIRECT - {\$env_label} ENVIRONMENT\\n\";
    \$note .= \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n\";
    \$note .= \"Original Recipient(s): {\$original_to}\\n\";
    \$note .= \"Redirected To: {\$test_email}\\n\";
    \$note .= \"Environment: {\$env_label}\\n\\n\";
    \$note .= \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\";
    \$note .= \"ORIGINAL MESSAGE BELOW:\\n\";
    \$note .= \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n\";

    \$args[\"message\"] = \$note . \$args[\"message\"];

    return \$args;
}, 999);

add_action(\"admin_notices\", function() use (\$test_email, \$wp_env) {
    \$env_label = strtoupper(\$wp_env);
    echo \"<div class=\"notice notice-warning\"><p><strong>⚠️  Email Redirect Active</strong> - All emails → <code>\" . esc_html(\$test_email) . \"</code> ({\$env_label})</p></div>\";
});

// Gravity Forms integration
if (class_exists(\"GFCommon\")) {
    add_filter(\"gform_notification\", function(\$notification, \$form, \$entry) use (\$test_email, \$wp_env) {
        \$original_to = \$notification[\"to\"];
        \$notification[\"to\"] = \$test_email;

        \$env_label = strtoupper(\$wp_env);
        if (strpos(\$notification[\"subject\"], \"[TEST - \") === false) {
            \$notification[\"subject\"] = \"[TEST - {\$env_label}] \" . \$notification[\"subject\"];
        }

        \$note = \"<div style=\\\"background:#f44336;color:#fff;padding:15px;margin-bottom:20px;\\\">\";
        \$note .= \"<strong>⚠️  TEST EMAIL - {\$env_label}</strong><br>\";
        \$note .= \"Form: {\$form[\"title\"]}<br>\";
        \$note .= \"Original: {\$original_to} → Redirected: {\$test_email}\";
        \$note .= \"</div><hr>\";

        \$notification[\"message\"] = \$note . \$notification[\"message\"];

        return \$notification;
    }, 999, 3);
}
EOF
chmod 644 /var/www/html/wp-content/mu-plugins/bbws-platform/test-email-redirect.php && echo \"✅ test-email-redirect.php deployed\"'" \
  --interactive \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION"

# Deploy environment-indicator.php
echo ""
echo "🚧 Deploying environment-indicator.php..."

aws ecs execute-command \
  --cluster "$CLUSTER" \
  --task "$TASK_ID" \
  --container "$CONTAINER" \
  --command "bash -c 'cat > /var/www/html/wp-content/mu-plugins/bbws-platform/environment-indicator.php << '\'EOF'\'
<?php
/**
 * Plugin Name: BBWS Platform - Environment Indicator
 * Description: Visual indicator for non-production environments
 * Version: 1.0.0
 */

\$wp_env = defined(\"WP_ENV\") ? WP_ENV : \"prod\";

if (!in_array(\$wp_env, [\"dev\", \"sit\"])) {
    return;
}

\$test_email = defined(\"TEST_EMAIL_REDIRECT\") ? TEST_EMAIL_REDIRECT : \"tebogo@bigbeard.co.za\";
\$color = \$wp_env === \"dev\" ? \"#ff6b6b\" : \"#ffa726\";

add_action(\"wp_footer\", function() use (\$wp_env, \$test_email, \$color) {
    \$env_label = strtoupper(\$wp_env);
    echo \"<div style=\\\"position:fixed;bottom:0;left:0;right:0;background:{\$color};color:#fff;text-align:center;padding:12px;font-weight:bold;z-index:999999;\\\"><strong>🚧 {\$env_label} ENVIRONMENT 🚧</strong><br><small>Emails → \" . esc_html(\$test_email) . \" • Analytics Mocked</small></div>\";
}, 999);

add_action(\"admin_bar_menu\", function(\$wp_admin_bar) use (\$wp_env, \$color) {
    \$env_label = strtoupper(\$wp_env);
    \$wp_admin_bar->add_node([
        \"id\" => \"bbws-env-indicator\",
        \"title\" => \"🚧 {\$env_label}\",
        \"href\" => \"#\",
        \"meta\" => [\"html\" => \"<style>#wp-admin-bar-bbws-env-indicator > .ab-item {background:{\$color}!important;color:#fff!important;}</style>\"]
    ]);
}, 999);

add_action(\"wp_head\", function() {
    echo \"<meta name=\\\"robots\\\" content=\\\"noindex,nofollow\\\">\";
}, 1);
EOF
chmod 644 /var/www/html/wp-content/mu-plugins/bbws-platform/environment-indicator.php && echo \"✅ environment-indicator.php deployed\"'" \
  --interactive \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION"

# Deploy bbws-platform.php loader
echo ""
echo "📦 Deploying bbws-platform.php loader..."

aws ecs execute-command \
  --cluster "$CLUSTER" \
  --task "$TASK_ID" \
  --container "$CONTAINER" \
  --command "bash -c 'cat > /var/www/html/wp-content/mu-plugins/bbws-platform.php << '\'EOF'\'
<?php
/**
 * Plugin Name: BBWS Platform - Environment Controls
 * Description: Manages environment-specific behavior for multi-tenant WordPress
 * Version: 1.0.0
 */

\$wp_env = defined(\"WP_ENV\") ? WP_ENV : \"prod\";

if (in_array(\$wp_env, [\"dev\", \"sit\"])) {
    require_once __DIR__ . \"/bbws-platform/force-https.php\";
    require_once __DIR__ . \"/bbws-platform/test-email-redirect.php\";
    require_once __DIR__ . \"/bbws-platform/environment-indicator.php\";
} else {
    require_once __DIR__ . \"/bbws-platform/force-https.php\";
}
EOF
chmod 644 /var/www/html/wp-content/mu-plugins/bbws-platform.php && echo \"✅ bbws-platform.php loader deployed\"'" \
  --interactive \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION"

# Move existing force-https.php
echo ""
echo "📦 Moving existing force-https.php to bbws-platform folder..."

aws ecs execute-command \
  --cluster "$CLUSTER" \
  --task "$TASK_ID" \
  --container "$CONTAINER" \
  --command "bash -c 'cp /var/www/html/wp-content/mu-plugins/force-https.php /var/www/html/wp-content/mu-plugins/bbws-platform/force-https.php && echo \"✅ force-https.php copied to bbws-platform/\"'" \
  --interactive \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All BBWS Platform MU-Plugins deployed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Deployed plugins:"
echo "  • bbws-platform.php (loader)"
echo "  • bbws-platform/force-https.php"
echo "  • bbws-platform/test-email-redirect.php"
echo "  • bbws-platform/environment-indicator.php"
echo ""
echo "Configuration:"
echo "  • WP_ENV: dev"
echo "  • TEST_EMAIL_REDIRECT: tebogo@bigbeard.co.za"
echo ""
echo "Next steps:"
echo "  1. Test email sending (should go to tebogo@bigbeard.co.za)"
echo "  2. Verify environment indicator on frontend"
echo "  3. Check admin bar for environment badge"
echo ""

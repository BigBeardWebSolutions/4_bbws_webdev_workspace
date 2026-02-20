#!/bin/bash
set -e

# Wait for the original entrypoint to generate wp-config.php
/usr/local/bin/docker-entrypoint.sh "$@" &
PID=$!

# Wait a bit for wp-config.php to be created
sleep 5

# Inject our custom configuration at the beginning of wp-config.php if it exists
if [ -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-custom.php ]; then
    # Check if already injected
    if ! grep -q "wp-config-custom.php" /var/www/html/wp-config.php; then
        # Prepend our custom config after the opening PHP tag
        sed -i '1a <?php require_once('"'"'/var/www/html/wp-config-custom.php'"'"'); ?>' /var/www/html/wp-config.php
    fi
fi

# Wait for the background process
wait $PID

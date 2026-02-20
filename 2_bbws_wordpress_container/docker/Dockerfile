FROM wordpress:latest

# Install WP-CLI and utilities
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    default-mysql-client \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create wp-cli config for running as www-data
RUN mkdir -p /var/www/.wp-cli && chown www-data:www-data /var/www/.wp-cli

# Copy mu-plugins (loaded automatically by WordPress)
COPY mu-plugins/ /usr/src/wordpress/wp-content/mu-plugins/

# Copy custom wp-config snippet
COPY wp-config-custom.php /var/www/html/

# Copy custom entrypoint
COPY docker-entrypoint-wrapper.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["apache2-foreground"]

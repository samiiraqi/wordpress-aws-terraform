FROM wordpress:php8.2-fpm
RUN docker-php-ext-install pdo_mysql
RUN cp -r /usr/src/wordpress/. /var/www/html/ && \
    chown -R www-data:www-data /var/www/html
EXPOSE 9000

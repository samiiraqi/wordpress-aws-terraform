FROM wordpress:php8.2-fpm

# Copy WordPress files into the image so they are ready immediately
RUN cp -r /usr/src/wordpress/. /var/www/html/ && \
    chown -R www-data:www-data /var/www/html

EXPOSE 9000

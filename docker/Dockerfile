FROM wordpress:php8.2-fpm
RUN apt-get update && apt-get remove -y linux-libc-dev libraw23t64 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo_mysql
RUN cp -r /usr/src/wordpress/. /var/www/html/ && \
    chown -R www-data:www-data /var/www/html
EXPOSE 9000
# test

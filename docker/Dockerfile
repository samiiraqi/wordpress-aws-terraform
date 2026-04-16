FROM wordpress:php8.2-fpm
RUN docker-php-ext-install pdo_mysql
RUN cp -r /usr/src/wordpress/. /var/www/html/ && \
    chown -R www-data:www-data /var/www/html
RUN apt-get update && apt-get upgrade -y && \
    apt-get remove -y linux-libc-dev libraw23t64 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 9000

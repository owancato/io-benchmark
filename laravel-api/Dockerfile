FROM php:8.4-fpm

# 安裝 Nginx 和必要的擴展
RUN apt-get update && apt-get install -y \
    nginx \
    git curl unzip \
    && docker-php-ext-install pdo pdo_mysql opcache \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www

# 複製 PHP 配置
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY src /var/www

# 複製 Nginx 配置
COPY nginx.conf /etc/nginx/sites-available/default

# 複製啟動腳本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 設定權限
RUN chown -R www-data:www-data /var/www \
    && mkdir -p /var/run/php \
    && chown -R www-data:www-data /var/run/php

EXPOSE 9000

CMD ["/start.sh"]

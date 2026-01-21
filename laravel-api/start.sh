#!/bin/bash

# 確保目錄存在
mkdir -p /var/run/php
mkdir -p /var/log/nginx

# 啟動 PHP-FPM（後台運行）
php-fpm -D

# 等待 PHP-FPM 啟動
sleep 2

# 檢查 PHP-FPM socket 是否建立
if [ ! -S /var/run/php/php8.4-fpm.sock ]; then
    echo "錯誤: PHP-FPM socket 未建立"
    exit 1
fi

echo "PHP-FPM 已啟動"
echo "Nginx 正在啟動..."

# 啟動 Nginx（前台運行）
nginx -g 'daemon off;'

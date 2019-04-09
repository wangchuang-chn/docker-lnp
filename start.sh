#!/bin/sh
/usr/local/php/sbin/php-fpm
chown nginx:nginx /var/run/php-fpm.sock
/usr/local/nginx/sbin/nginx
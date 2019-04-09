#!/bin/sh
/usr/local/php/sbin/php-fpm
chown www:www /var/run/php-fpm.sock
/usr/local/nginx/sbin/nginx
#!/bin/sh
supervisord -c /etc/supervisord.conf 
/usr/local/php/sbin/php-fpm
/usr/local/nginx/sbin/nginx
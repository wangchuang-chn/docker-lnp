FROM centos:7

MAINTAINER wangchuang<mail.wangchuang@gmail.com>

EXPOSE 80

ENV NGINX_VERSION 1.10.0
ENV PHP_VERSION 7.1.13


ENV NGINX_PREFIX_CONFIG "\
    --prefix=/usr/local/nginx \
    --user=nginx \
    --group=nginx \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-ipv6"


#install nginx
RUN \
    yum -y install gcc-c++ \
        make \
        curl \
        zlib-devel \
        pcre-devel \
    && cd /usr/local/src/ \
    && groupadd  nginx \
    && useradd  -s /sbin/nologin -g nginx nginx \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && tar xf nginx.tar.gz \
    && cd nginx-$NGINX_VERSION \
    && ./configure $NGINX_PREFIX_CONFIG \
    && make \
    && make install \
    && cd / \
    && rm -rf /usr/local/src/* \
    && ls -l /usr/local/nginx \
    && /usr/local/nginx/sbin/nginx


#install php

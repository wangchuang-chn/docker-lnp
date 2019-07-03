FROM centos:7

MAINTAINER wangchuang<mail.wangchuang@gmail.com>

EXPOSE 80

ENV NGINX_VERSION 1.10.0
ENV PHP_VERSION 7.1.8


ENV NGINX_PREFIX_CONFIG "\
    --prefix=/usr/local/nginx \
    --user=nginx \
    --group=nginx \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-ipv6"


ENV PHP_PREFIX_CONFIG "\
    --prefix=/usr/local/php \
    --enable-fpm \
    --enable-mysqlnd \
    --with-curl \
    --with-openssl \
    --with-mcrypt \
    --enable-mbstring \
    --with-gd \
    --with-jpeg-dir=/usr/lib64  \
    --with-png-dir \
    --enable-zip \
    --enable-bcmath"



#install nginx
RUN \
    yum -y install gcc-c++ \
        git \
        make \
        curl \
        zlib-devel \
        pcre-devel \
        wget \
        epel-release \
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
    && mkdir /usr/local/nginx/conf.d \
    && rm -rf /usr/local/nginx/html \
    #install php
    && yum -y install libxml2-devel \
        openssl-devel \
        libcurl-devel \
        libjpeg-devel \
        libpng-devel \
        libmcrypt-devel \
    && cd /usr/local/src \
    && wget https://github.com/wangchuang-chn/docker-lnp/raw/master/soft/php-${PHP_VERSION}.tar.gz  \
    && tar xf php-${PHP_VERSION}.tar.gz \
    && cd php-$PHP_VERSION \
    && ./configure $PHP_PREFIX_CONFIG \
    && make\
    && make install \
    && rm -rf /usr/local/src/* \
    && cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
    && cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s@user = nobody@user = nginx@g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s@group = nobody@group = nginx@g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\.sock/g"  /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/;listen.owner = nobody/listen.owner = nginx/g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/;listen.group = nginx/;listen.group = nginx/g" /usr/local/php/etc/php-fpm.d/www.conf \
    && yum clean all \
    && echo 'PATH=/usr/local/php/bin:/usr/local/nginx/sbin/:$PATH' >> /etc/profile \
    && source /etc/profile \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer



ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD nginx-site.conf /usr/local/nginx/conf.d/default.conf

ADD start.sh /start.sh
CMD ["/bin/sh", "/start.sh"]

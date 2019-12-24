FROM centos:7

MAINTAINER wangchuang<mail.wangchuang@gmail.com>

EXPOSE 80
EXPOSE 443

ENV NGINX_VERSION 1.10.0
ENV PHP_VERSION 7.1.8


ENV NGINX_PREFIX_CONFIG "\
    --prefix=/usr/local/nginx \
    --user=nginx \
    --group=nginx \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-ipv6 \
    --with-http_ssl_module"


ENV PHP_PREFIX_CONFIG "\
    --prefix=/usr/local/php \
    --enable-fpm \
    --enable-mysqlnd \
    --with-pdo-mysql \
    --with-curl \
    --with-openssl \
    --with-mcrypt \
    --enable-mbstring \
    --with-gd \
    --with-jpeg-dir=/usr/lib64  \
    --with-png-dir \
    --enable-zip \
    --enable-pcntl \
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
        python-setuptools \
        vixie-cron \
        crontabs \
    && yum -y install libxml2-devel \
        openssl-devel \
        libcurl-devel \
        libjpeg-devel \
        libpng-devel \
        libmcrypt-devel \
    && chkconfig --level 345 crond on \
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
    && cd /usr/local/src \
    && wget https://github.com/wangchuang-chn/docker-lnp/raw/master/soft/php-${PHP_VERSION}.tar.gz  \
    && tar xf php-${PHP_VERSION}.tar.gz \
    && wget https://files.pythonhosted.org/packages/19/0a/7eef85a26f8dfb585f312e4c6b76b0b16fe800ffce8a4724a7bda6ef440d/supervisor-3.4.0.tar.gz \
    && tar xf supervisor-3.4.0.tar.gz \
    && cd supervisor-3.4.0 \
    && python setup.py install \
    && echo_supervisord_conf > /etc/supervisord.conf \
    && echo -e "[include]\nfiles = /etc/supervisord/*.conf" >> /etc/supervisord.conf \
    && mkdir /etc/supervisord/ \
    && cd /usr/local/src/php-$PHP_VERSION \
    && ./configure $PHP_PREFIX_CONFIG \
    && make \
    && make install \
    && cp php.ini-production /usr/local/php/lib/php.ini \
    && sed -i 's@memory_limit.*@memory_limit = 257M@g' /usr/local/php/lib/php.ini \
    && sed -i 's@disable_functions.*@disable_functions =eval,passthru,system,chroot,chgrp,chown,shell_exec,error_log,ini_alter,ini_restore,dl,pfsockopen,syslog,readlink,stream_socket_server@g' /usr/local/php/lib/php.ini \
    && rm -rf /usr/local/src/* \
    && cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
    && cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s@user = nobody@user = nginx@g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s@group = nobody@group = nginx@g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\.sock/g"  /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/;listen.owner = nobody/listen.owner = nginx/g" /usr/local/php/etc/php-fpm.d/www.conf \
    && sed -i -e "s/;listen.group = nginx/;listen.group = nginx/g" /usr/local/php/etc/php-fpm.d/www.conf \
    && yum clean all \
    && ln -s /usr/local/php/bin/php /usr/bin/ \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && echo -e "HOME=/tmp\n* * * * *  /usr/local/php/bin/php /usr/share/nginx/html/artisan schedule:run >> /dev/null 2>&1" > /var/spool/cron/nginx \
    && echo -e "[program:ccshop]\nprocess_name=%(program_name)s_%(process_num)02d\ncommand= /usr/local/php/bin/php /usr/share/nginx/html/artisan queue:listen --tries=5 --timeout=0\nautostart=true\nautorestart=true\nnumprocs=2\nredirect_stderr=true\nuser=nginx\n" > /etc/supervisord/ccshop.conf \
    && supervisord -c /etc/supervisord.conf \


ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD nginx-site.conf /usr/local/nginx/conf.d/default.conf
ADD cloudflare.pem /usr/local/nginx/conf/ssl/cloudflare.pem
ADD cloudflare.key /usr/local/nginx/conf/ssl/cloudflare.key


ADD start.sh /start.sh
CMD ["/bin/sh", "/start.sh"]

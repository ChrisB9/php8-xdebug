FROM php:8.0.0alpha3-fpm-alpine

ENV TERM="xterm" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"
ENV DOCKER_CONF_HOME=/opt/docker/
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000
ENV NGINX_VERSION 1.19.1
ENV NGX_BROTLI_COMMIT 25f86f0bac1101b6512135eac5f93c49c63609e3

COPY conf/ /opt/docker/

# install dependencies
RUN apk add --no-cache \
    		gcc \
    		libc-dev \
    		make \
    		openssl-dev \
    		pcre-dev \
    		zlib-dev \
    		linux-headers \
    		curl \
    		gnupg1 \
    		libxslt-dev \
    		gd-dev \
    		geoip-dev \
    		perl-dev \
    		autoconf \
    		libtool \
    		automake \
    		git \
    		g++ \
    		cmake \
    		sudo \
    	&& apk add --no-cache --virtual .gettext gettext

# Add groups and users
RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx
RUN addgroup -g $APPLICATION_GID $APPLICATION_GROUP \
    && echo '%application ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/application \
    && adduser -D -u $APPLICATION_UID -s /bin/bash -G $APPLICATION_GROUP $APPLICATION_USER

RUN mkdir -p /usr/src \
    && cd /usr/src \
    && git clone --recursive https://github.com/google/ngx_brotli.git \
    && cd ngx_brotli \
    && git submodule update --init --recursive \
    && cd deps/brotli \
    && mkdir out \
    && cd out \
    && cmake .. \
    && make -j 16 brotli \
    && cp brotli /usr/local/bin/brotli
RUN cd /usr/src \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ls -la /usr/src/ngx_brotli \
    && CONFIG=" \
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --user=nginx \
            --group=nginx \
            --with-http_ssl_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_stub_status_module \
            --with-http_auth_request_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_perl_module=dynamic \
            --with-mail \
            --with-mail_ssl_module \
            --with-file-aio \
            --with-threads \
            --with-stream \
            --with-compat \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-http_slice_module \
            --with-http_v2_module \
            --with-debug \
            --add-dynamic-module=/usr/src/ngx_brotli \
    " \
    && ./configure $CONFIG \
    && make \
    && make install

RUN mkdir -p /etc/nginx/modules-enabled/ \
    && mkdir -p /usr/lib/nginx/modules \
    && ln -s /etc/nginx/modules /usr/lib/nginx/modules \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && cp objs/*.so /usr/lib/nginx/modules \
    && echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;" >> /etc/nginx/modules-enabled/brotli.conf \
    && echo "load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;" >> /etc/nginx/modules-enabled/brotli.conf \
    && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps tzdata $runDeps \
    && mv /tmp/envsubst /usr/local/bin/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /app/ \
    && touch /app/index.html \
    && echo "<h1>It Works!</h1>" >> /app/index.html

RUN apk update && apk add --no-cache supervisor openssh libwebp-tools sshpass jpegoptim optipng pngquant git wget vim nano less tree bash-completion mariadb-client

STOPSIGNAL SIGQUIT

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    &&  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer2 --version=2.0.0-alpha2

USER application

RUN curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1{print $NF}')/contrib/completion/git-completion.bash > /home/application/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1{print $NF}')/contrib/completion/git-prompt.sh > /home/application/.git-prompt.sh
RUN composer global require hirak/prestissimo davidrjonas/composer-lock-diff perftools/php-profiler && \
    composer clear
COPY user/* /home/application/
RUN echo "source ~/bashconfig.sh" >> ~/.bashrc

USER root
COPY user/* /root/
RUN mkdir -p /opt/php-libs
COPY php/* /opt/php-libs/files/

# activate opcache and jit
RUN mv /opt/php-libs/files/opcache-jit.ini /usr/local/etc/php/conf.d/docker-php-opcache-jit.ini

# install pcov
RUN cd /opt/php-libs \
    && git clone https://github.com/krakjoe/pcov.git \
    && cd pcov \
    && phpize \
    && ./configure --enable-pcov \
    && make \
    && make install \
    && docker-php-ext-enable pcov \
    && mv /opt/php-libs/files/pcov.ini /usr/local/etc/php/conf.d/docker-php-pcov.ini

# install xdebug 3.0
RUN cd /opt/php-libs \
    && git clone https://github.com/xdebug/xdebug \
    && cd xdebug \
    # the last working commit, because the php-src is not up to date yet in this alpine
    && phpize \
    && ./configure --enable-xdebug-dev \
    && make all \
    && mv /opt/php-libs/files/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# install tideways
RUN cd /opt/php-libs \
     && git clone https://github.com/tideways/php-xhprof-extension \
     && cd php-xhprof-extension \
     && phpize \
     && ./configure \
     && make \
     && make install \
     && mkdir -p /opt/docker/profiler \
     && mv /opt/php-libs/files/xhprof.ini /usr/local/etc/php/conf.d/docker-php-ext-xhprof.ini

RUN curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1{print $NF}')/contrib/completion/git-completion.bash > /root/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1{print $NF}')/contrib/completion/git-prompt.sh > /root/.git-prompt.sh

EXPOSE 80 443 9000
CMD ["/usr/bin/supervisord", "-c", "/opt/docker/supervisord.conf"]

WORKDIR /app

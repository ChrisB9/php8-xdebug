FROM php:8.0.0-fpm-alpine

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
ENV XDEBUG_VERSION="3.0.0"
ENV IS_CLI=false
ENV IS_ALPINE=true

COPY conf/ /opt/docker/
# install dependencies
RUN apk add --no-cache \
    		aom-dev \
    		bash-completion \
    		curl \
    		gd-dev \
    		geoip-dev \
    		git \
    		gnupg1 \
    		imagemagick \
    		jpegoptim \
    		less \
    		libffi-dev \
    		libgit2 \
    		libwebp-tools \
    		libxslt-dev \
    		make \
    		mariadb-client \
    		openssh \
    		openssl-dev \
    		optipng \
    		pcre-dev \
    		pngquant \
    		sshpass \
    		sudo \
    		supervisor \
    		tree \
    		vim \
    		wget \
    		zlib-dev \
    	&& apk add --no-cache --virtual .build-deps \
    	    autoconf \
    	    automake \
    	    cargo \
    	    cmake \
    	    g++ \
    	    gcc \
    	    gettext \
    		go \
    		libc-dev \
    		libtool \
    		linux-headers \
    		musl-dev \
    		perl-dev \
    		rust


# Add groups and users

RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx
RUN addgroup -g $APPLICATION_GID $APPLICATION_GROUP \
    && echo "%$APPLICATION_GROUP ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$APPLICATION_USER \
    && adduser -D -u $APPLICATION_UID -s /bin/bash -G $APPLICATION_GROUP $APPLICATION_USER \
    && addgroup $APPLICATION_USER nginx

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

# hadolint ignore=DL3022
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

RUN go get github.com/Kagami/go-avif \
    && cd /root/go/src/github.com/Kagami/go-avif \
    && make all \
    && mv /root/go/bin/avif /usr/local/bin/avif

STOPSIGNAL SIGQUIT

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > /root/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > /root/.git-prompt.sh \
    && curl https://raw.githubusercontent.com/ogham/exa/master/completions/completions.bash > /root/.completions.bash

USER application

RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > /home/$APPLICATION_USER/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > /home/$APPLICATION_USER/.git-prompt.sh \
    && curl https://raw.githubusercontent.com/ogham/exa/master/completions/completions.bash > /home/$APPLICATION_USER/.completions.bash
RUN composer global require perftools/php-profiler && composer clear
COPY user/* /home/$APPLICATION_USER/
RUN echo "source ~/bashconfig.sh" >> ~/.bashrc

USER root
COPY user/* /root/
RUN mkdir -p /opt/php-libs
COPY php/* /opt/php-libs/files/

# activate opcache and jit
RUN mv /opt/php-libs/files/opcache-jit.ini "$PHP_INI_DIR/conf.d/docker-php-opcache-jit.ini"

RUN install-php-extensions \
    pcov \
    mongodb \
    ffi \
    gd \
    pcntl
RUN mv /opt/php-libs/files/pcov.ini "$PHP_INI_DIR/conf.d/docker-php-pcov.ini" \
    && mkdir /tmp/debug \
    && chmod -R 777 /tmp/debug \
    # && mkdir -p /opt/docker/profiler \
    # && mv /opt/php-libs/files/xhprof.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xhprof.ini" \
    && git clone -b $XDEBUG_VERSION --depth 1 https://github.com/xdebug/xdebug.git /usr/src/php/ext/xdebug \
    && docker-php-ext-configure xdebug --enable-xdebug-dev \
    && mv /opt/php-libs/files/xdebug.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" \
    && docker-php-ext-install xdebug

ENV \
    COMPOSER_HOME=/home/$APPLICATION_USER/.composer \
    POSTFIX_RELAYHOST="[global-mail]:1025" \
    PHP_DISPLAY_ERRORS="1" \
    PHP_MEMORY_LIMIT="-1" \
    TZ=Europe/Berlin

WORKDIR /tmp

ENV PATH=/usr/local/cargo/bin:$PATH

RUN git clone https://github.com/ogham/exa \
    && cd exa \
        && cargo build --release \
    && mv target/release/exa /usr/local/bin/exa \
    && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin/ \
    && rm -rf /tmp/exa

COPY entrypoint/entrypoint.sh /entrypoint
COPY entrypoint/scripts /entrypoint.d/
COPY bins/ /usr-bins/
RUN chmod +x /entrypoint.d/*.sh /entrypoint /usr-bins/* \
    && mv /usr-bins/* /usr/local/bin/ \
    && mkdir -p /var/log/supervisord


RUN apk del .build-deps .nginx-rundeps



ENTRYPOINT ["/entrypoint"]
EXPOSE 80 443 9003

WORKDIR /app

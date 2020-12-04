FROM {base.from}

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
ENV XDEBUG_VERSION="3.0.0beta1"
ENV COMPOSER2_VERSION="2.0.0-alpha3"

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

COPY conf/ /opt/docker/

# Add groups and users
RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx
{{ if is_dev }}
RUN addgroup -g $APPLICATION_GID $APPLICATION_GROUP \
    && echo '%application ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/application \
    && adduser -D -u $APPLICATION_UID -s /bin/bash -G $APPLICATION_GROUP $APPLICATION_USER
{{ else }}
RUN addgroup -g $APPLICATION_GID $APPLICATION_GROUP \
    && adduser -D -u $APPLICATION_UID -s /bin/bash -G $APPLICATION_GROUP $APPLICATION_USER
{{ endif }}

{{ call nginx_partial_dockerfile with base }}

RUN apk update && apk add --no-cache supervisor openssh libwebp-tools sshpass go aom-dev imagemagick jpegoptim optipng pngquant git wget vim nano less tree bash-completion mariadb-client
RUN go get github.com/Kagami/go-avif \
    && cd /root/go/src/github.com/Kagami/go-avif \
    && make all \
    && mv /root/go/bin/avif /usr/local/bin/avif

STOPSIGNAL SIGQUIT

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    &&  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer2 --version=$COMPOSER2_VERSION

USER application

RUN curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1\{print $NF}')/contrib/completion/git-completion.bash > /home/application/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1\{print $NF}')/contrib/completion/git-prompt.sh > /home/application/.git-prompt.sh
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
    && wget https://github.com/xdebug/xdebug/archive/$XDEBUG_VERSION.tar.gz \
    && mkdir xdebug && tar -zxC ./xdebug -f $XDEBUG_VERSION.tar.gz --strip-components 1 \
    && rm  $XDEBUG_VERSION.tar.gz \
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

RUN curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1\{print $NF}')/contrib/completion/git-completion.bash > /root/.git-completion.bash \
    && curl https://raw.githubusercontent.com/git/git/v$(git --version | awk 'NF>1\{print $NF}')/contrib/completion/git-prompt.sh > /root/.git-prompt.sh
RUN mkdir -p /var/log/supervisord
EXPOSE 80 443 9000
CMD ["/usr/bin/supervisord", "-nc", "/opt/docker/supervisord.conf"]

WORKDIR /app


FROM {base.from}

ENV TERM="xterm" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"
ENV DOCKER_CONF_HOME=/opt/docker/
ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000 {{- if base.is_web }}
ENV NGINX_VERSION 1.19.1
ENV NGX_BROTLI_COMMIT 25f86f0bac1101b6512135eac5f93c49c63609e3{{- endif }}
{{ if is_dev }}ENV XDEBUG_VERSION="{base.envs.XDEBUG_VERSION}"{{ endif }}
ENV IS_CLI={{- if base.is_web }}false{{- else }}true{{- endif }}
ENV IS_ALPINE={{- if base.use_apk }}true{{- else }}false{{- endif }}

COPY conf/ /opt/docker/

{{- if base.use_apk }}
{{ call dependencies_alpine_dockerfile with base }}
{{- else }}
{{ call dependencies_debian_dockerfile with base }}
{{- endif }}

# Add groups and users
{{ if base.use_apk }}
RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx
RUN addgroup -g $APPLICATION_GID $APPLICATION_GROUP \ {{- if is_dev }}
    && echo "%$APPLICATION_GROUP ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$APPLICATION_USER \ {{- endif }}
    && adduser -D -u $APPLICATION_UID -s /bin/bash -G $APPLICATION_GROUP $APPLICATION_USER {{- if base.is_web }} \
    && addgroup $APPLICATION_USER nginx {{- endif }}
{{ else }}
{{- if base.is_web }}
RUN groupadd -g 103 nginx \
    && adduser --gecos "" --disabled-password --system --home /var/cache/nginx --shell /sbin/nologin --ingroup nginx nginx {{- endif }}
RUN groupadd -g $APPLICATION_GID $APPLICATION_GROUP \ {{- if is_dev }}
    && echo "%$APPLICATION_GROUP ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$APPLICATION_USER \ {{- endif }}
    && adduser --gecos "" --disabled-password --uid $APPLICATION_UID --shell /bin/bash --ingroup $APPLICATION_GROUP $APPLICATION_USER {{- if base.is_web }} \
    && usermod -aG nginx $APPLICATION_USER {{- endif }}
{{ endif }}

{{- if base.is_web }}
{{ call nginx_partial_dockerfile with base }}
{{- endif }}

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

RUN install-php-extensions \ {{- if is_dev }}
    pcov \ {{- endif }}
    mongodb \
    gd \
    pcntl

{{- if is_dev }}
RUN mv /opt/php-libs/files/pcov.ini "$PHP_INI_DIR/conf.d/docker-php-pcov.ini" \
    && mkdir /tmp/debug \
    && chmod -R 777 /tmp/debug \
    # && mkdir -p /opt/docker/profiler \
    # && mv /opt/php-libs/files/xhprof.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xhprof.ini" \
    && git clone -b $XDEBUG_VERSION --depth 1 https://github.com/xdebug/xdebug.git /usr/src/php/ext/xdebug \
    && docker-php-ext-configure xdebug --enable-xdebug-dev \
    && mv /opt/php-libs/files/xdebug.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" \
    && docker-php-ext-install xdebug \
    && echo "ffi.enable=preload" >> "$PHP_INI_DIR/conf.d/docker-php-ffi.ini"
{{- endif }}

ENV \
    COMPOSER_HOME=/home/$APPLICATION_USER/.composer \
    POSTFIX_RELAYHOST="[global-mail]:1025" \
    PHP_DISPLAY_ERRORS="1" \
    PHP_MEMORY_LIMIT="-1" \
    TZ=Europe/Berlin

{{ call docker_partial_dockerfile with base }}

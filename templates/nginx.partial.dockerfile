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
            | awk '\{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
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
WORKDIR /tmp

ENV PATH=/usr/local/cargo/bin:$PATH

RUN git clone https://github.com/ogham/exa \
    && cd exa \ {{- if use_apk }}
        && cargo build --release \
    {{- else }}
        && /root/.cargo/bin/cargo build --release \
    {{- endif }}
    && mv target/release/exa /usr/local/bin/exa \
    && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin/ \
    && rm -rf /tmp/exa

RUN wget https://github.com/dalance/amber/releases/download/v0.5.8/amber-v0.5.8-x86_64-lnx.zip \
    && unzip amber-v0.5.8-x86_64-lnx.zip \
    && rm amber-v0.5.8-x86_64-lnx.zip \
    && mv amb* /usr/local/bin/

COPY entrypoint/entrypoint.sh /entrypoint
COPY entrypoint/scripts /entrypoint.d/
COPY bins/ /usr-bins/
RUN chmod +x /entrypoint.d/*.sh /entrypoint /usr-bins/* \
    && mv /usr-bins/* /usr/local/bin/ \
    && mkdir -p /var/log/supervisord

{{ if use_apk }}
RUN apk del .build-deps .nginx-rundeps
{{ else }}
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get remove -y \
        automake \
        cmake \
        g++ \
        gettext \
        golang-go\
        libtool \
    && /root/.cargo/bin/rustup self uninstall -y
{{ endif }}


ENTRYPOINT ["/entrypoint"]

{{- if is_web }}
EXPOSE 80 443 9003
{{- endif }}

WORKDIR /app

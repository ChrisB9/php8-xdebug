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

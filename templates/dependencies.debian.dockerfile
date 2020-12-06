# install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    		apt-transport-https \
    		autoconf \
    		automake \
            automake \
            bash-completion \
            cmake \
            curl \
            g++ \
            gcc \
            gettext \
            git \
            git \
            gnupg1 \
            golang-go\
            imagemagick \
            jpegoptim \
            less \
            libaom-dev \
            libffi-dev \
            libgd-dev \
            libgeoip-dev \
            libpcre3 \
            libpcre3-dev \
            libperl-dev \
            libssl-dev \
            libtool \
            libwebp-dev \
            libxslt-dev \
            make \
            mariadb-client \
            openssh-client \
            openssl \
    	    optipng \
    	    pngquant \
    	    socat \
    	    sshpass \
    		sudo \
    		supervisor \
    		tree \
    		vim \
    		wget \
    	&& rm -rf /var/lib/apt/lists/*

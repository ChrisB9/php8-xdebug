# PHP 8.0 with xdebug and pcov

current features:
- nginx with brotli and http2 enabled
- php 8.0 rc5 (with xdebug, opcache and jit enabled by default)
- xdebug 3.0 (set to profile, debug and develop-mode)
- pcov
- composer v2.0 (composer 1.0 has been removed)
- bash (with auto-completion extension and colored)
- tideways profiler with perf-tools enabled
- webp and image-optimizers
- mariadb support

planned:
- mongodb support

### docker-socket

If docker socket has been mounted as a volume into the container,  
then each startup checks the availability of the docker command and if not available installs it.

## xdebug settings:

Some xdebug settings have been preconfigured, such as:
- `xdebug.mode=profile,develop,coverage`
- `xdebug.client_port=9003`
- `xdebug.discover_client_host=1`
- `xdebug.idekey=PHPSTORM`

Through the environment-variable `XDEBUG_HOST` the client_host can be changed on login

### xdebug tools:
- `xdebug-enable` enabled xdebug and restarts php
- `xdebug-disable` disables xdebug and restarts php

## testing this dockerfile:

just run `git clone && docker-compose up -d` <br />
then open up your browser and go to this container.

in the app-folder are two files index.php and Test.php.
They are meant as a playground to test the newest features of php 8.0


# PHP 8.0 for development and production

> **Note**:  
> This image is transitioning from a simple dev image to a more configurable and extensible image  
> Therefore it is currently being pushed into two different docker repositories:  
> (old:) [https://hub.docker.com/r/chrisb9/php8-nginx-xdebug](https://hub.docker.com/r/chrisb9/php8-nginx-xdebug)  
> (new:) [https://hub.docker.com/r/chrisb9/php8](https://hub.docker.com/r/chrisb9/php8)  

## The Images:

There are three image configurations in two different types:

| Image Type | Image Variant | With nginx |
|:----------:|:-------------:|:----------:|
| Alpine     | dev and prod  |     yes    |
| Debian     | dev and prod  |     yes    |
| CLI        | dev and prod  |      no    |

### current features

- **nginx based image:** nginx with brotli and http2 enabled
- **dev image:** php 8.0 ✨ (with xdebug, opcache, ffi, and jit enabled by default)
- **prod image:** php 8.0 ✨ (with opcache, and jit enabled by default)
- **dev image:** xdebug 3.0 (set to profile, debug and develop-mode)
- **dev image:** pcov
- composer v2.0 (composer 1.0 has been removed)
- bash (with auto-completion extension and colored)
- webp and image-optimizers
- mariadb support
- **cli image**: no fpm and no nginx preinstalled - this is your smaller variant, not based on alpine (yet)

planned:
- mongodb support
- apache-based image
- easier extension installation
- tideways profiler with perf-tools enabled

This repository does only provide Dockerfiles for php 8.0 and upwards.  
If there is enough traction, I might add PHP 7.4 too (or feel free to add it)

### docker-socket

If docker socket has been mounted as a volume into the container,  
then each startup checks the availability of the docker command and if not available installs it.
> Note: This is currently only available in alpine images: WIP

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

## Contributing

todo...

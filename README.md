# PHP 8.0 with xdebug and pcov

current features:
- nginx with brotli and http2 enabled
- php 8.0 rc1 (with xdebug, opcache and jit enabled by default)
- xdebug 3.0-dev (set to profile,debug and develop-mode)
- pcov
- composer and composer2.0 (available as `composer2`)
- bash (with auto-completion extension and colored)
- tideways profiler with perf-tools enabled
- webp and image-optimizers

#### testing this dockerfile:

just run `git clone && docker-compose up -d` <br />
then open up your browser and go to this container.

in the app-folder are two files index.php and Test.php.
They are meant as a playground to test the newest features of php 8.0



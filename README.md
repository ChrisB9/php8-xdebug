# PHP 8.0 with xdebug and pcov

currently features:
- nginx with brotli and http2 enabled
- php 8.0 alpha2 (july; with opcache and jit enabled by default)
- xdebug 3.0-dev
- pcov
- composer
- bash (with auto-completion extension and colored)
- tideways profiler (installed but not activated)

#### testing this dockerfile:

just run `git clone && docker-compose up -d` <br />
then open up your browser and go to this container.

in the app-folder are two files index.php and Test.php.
They are meant as a playground to test the newest features of php 8.0


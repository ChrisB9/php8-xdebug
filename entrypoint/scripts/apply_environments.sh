#!/usr/bin/env bash

function listEnvs() {
  env | grep "^${1}" | cut -d= -f1
}

function getEnvVar() {
  awk "BEGIN {print ENVIRON[\"$1\"]}"
}

for ENV_VAR in $(listEnvs "php\."); do
  env_key=${ENV_VAR#php.}
  env_val=$(getEnvVar "$ENV_VAR")

  echo "$env_key = ${env_val}" >> /usr/local/etc/php/conf.d/x.override.php.ini
done

if [[ -n "${XDEBUG_HOST}" ]]; then
  cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini | sed "s|\#\ xdebug\.client\_host\ \=|xdebug\.client\_host=${XDEBUG_HOST}|g" >> /tmp/xdebug.ini
  mv /tmp/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi

test -z "$PHP_MEMORY_LIMIT" && echo "memory_limit = ${PHP_MEMORY_LIMIT}" >> /usr/local/etc/php/conf.d/x.override.php.ini
test -z "$PHP_DISPLAY_ERRORS" && echo "memory_limit = ${PHP_DISPLAY_ERRORS}" >> /usr/local/etc/php/conf.d/x.override.php.ini
#!/usr/bin/env bash

ambr --no-interactive '${WEB_DOCUMENT_ROOT}' "$WEB_DOCUMENT_ROOT" /opt/docker/nginx/
ambr --no-interactive '${WEB_DOCUMENT_INDEX}' "$WEB_DOCUMENT_INDEX" /opt/docker/nginx/
ambr --no-interactive '${WEB_ALIAS_DOMAIN}' "$WEB_ALIAS_DOMAIN" /opt/docker/nginx/
ambr --no-interactive '${WEB_PHP_TIMEOUT}' "$WEB_PHP_TIMEOUT" /opt/docker/nginx/
ambr --no-interactive '${WEB_PHP_SOCKET}' "$WEB_PHP_SOCKET" /opt/docker/nginx/
ambr --no-interactive '${NGINX_CLIENT_MAX_BODY}' "$NGINX_CLIENT_MAX_BODY" /opt/docker/nginx/
ambr --no-interactive '${WEB_NO_CACHE_PATTERN}' "$WEB_NO_CACHE_PATTERN" /opt/docker/nginx/
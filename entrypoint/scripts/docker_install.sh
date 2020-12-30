#!/usr/bin/env bash

if [ -e /var/run/docker.sock ] && [ -n "$IS_ALPINE" ]; then
   apk add docker
fi
if [ -e /var/run/docker.sock ] && [ -z "$IS_ALPINE" ]; then
   apt update && apt install docker
fi

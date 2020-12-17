#!/usr/bin/env bash

set -o pipefail
set -o errtrace

for filename in /entrypoint.d/*.sh; do
  [ -e "$filename" ] || continue;
  echo "Running now: $filename"
  bash "$filename"
done;

exec /usr/bin/supervisord -nc /opt/docker/supervisord.conf

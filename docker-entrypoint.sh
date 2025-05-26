#!/bin/sh
set -e

# Run init scripts
if [ -d "/docker-entrypoint-init.d" ]; then
  for f in /docker-entrypoint-init.d/*.sh; do
    if [ -f "$f" ]; then
      echo "Running $f"
      "$f"
    fi
  done
fi

# Switch to pleroma user and run the command
cd /opt/pleroma
if [ $# -eq 0 ]; then
  exec su pleroma -s /bin/sh -c "mix ecto.migrate && mix phx.server"
else
  exec su pleroma -s /bin/sh -c "$*"
fi 
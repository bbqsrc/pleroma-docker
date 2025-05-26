#!/bin/sh
# Create overlay mount for config directory
if [ -d "/config" ]; then
  echo "Setting up overlay filesystem for config..."
  mount -t overlay overlay \
    -o lowerdir=/opt/pleroma/config,upperdir=/config,workdir=/config-overlay/work \
    /opt/pleroma/config
fi 
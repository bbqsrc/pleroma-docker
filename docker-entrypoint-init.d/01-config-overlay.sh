#!/bin/sh
# Create overlay mount for config directory
if [ -d "/config" ]; then
  echo "Setting up overlay filesystem for config..."
  
  # Debug: Check if directories exist
  echo "Checking directories:"
  echo "  /opt/pleroma/config exists: $(test -d /opt/pleroma/config && echo yes || echo no)"
  echo "  /config exists: $(test -d /config && echo yes || echo no)"
  echo "  /config-overlay/work exists: $(test -d /config-overlay/work && echo yes || echo no)"
  
  # Ensure work directory is empty
  rm -rf /config-overlay/work/*
  
  # Create a temporary mount point for the overlay
  mkdir -p /tmp/config-overlay
  
  # Mount the overlay to the temporary location
  if mount -t overlay overlay \
    -o lowerdir=/opt/pleroma/config,upperdir=/config,workdir=/config-overlay/work \
    /tmp/config-overlay; then
    echo "Overlay mount successful"
    
    # Bind mount the overlay over the original config directory
    if mount --bind /tmp/config-overlay /opt/pleroma/config; then
      echo "Bind mount successful"
    else
      echo "Bind mount failed"
    fi
  else
    echo "Overlay mount failed, falling back to simple bind mount"
    mount --bind /config /opt/pleroma/config
  fi
fi 
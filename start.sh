#!/bin/sh
set -e

echo "Starting Pleroma setup..."

# Check if prod.secret.exs exists in the mounted config directory
if [ -f "/config/prod.secret.exs" ]; then
    echo "Found existing prod.secret.exs, copying to Pleroma config directory..."
    cp /config/prod.secret.exs /opt/pleroma/config/prod.secret.exs
    echo "Configuration loaded successfully"
else
    echo "No prod.secret.exs found, running configuration generator..."
    
    # Run the Pleroma instance generator
    mix pleroma.instance gen
    
    # Copy the generated config to the mounted directory for persistence
    if [ -f "/opt/pleroma/config/generated_config.exs" ]; then
        echo "Copying generated config to /config for persistence..."
        cp /opt/pleroma/config/generated_config.exs /config/prod.secret.exs
        cp /opt/pleroma/config/generated_config.exs /opt/pleroma/config/prod.secret.exs
        echo "Configuration generated and saved"
        exit 0
    else
        echo "ERROR: Configuration generation failed - no generated_config.exs found"
        exit 1
    fi
fi

echo "Running database migrations..."
mix ecto.migrate

echo "Starting Pleroma server..."
exec mix phx.server

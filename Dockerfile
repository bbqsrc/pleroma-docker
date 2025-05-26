# Multi-stage build for Pleroma on Alpine Linux
# Based on https://docs.pleroma.social/backend/installation/alpine_linux_en/

# Build stage
FROM alpine:3.21 AS builder

# Build argument for Pleroma version (can be a branch, tag, or commit hash)
ARG PLEROMA_VERSION=stable

RUN awk 'NR==2' /etc/apk/repositories | sed 's/main/community/' | tee -a /etc/apk/repositories

# Install build dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache \
    git \
    build-base \
    cmake \
    file-dev \
    erlang \
    elixir \
    postgresql-client
        
# Create pleroma user
RUN addgroup pleroma && \
    adduser -S -s /bin/false -h /opt/pleroma -H -G pleroma pleroma

# Clone Pleroma repository
WORKDIR /opt/pleroma
RUN git clone https://git.pleroma.social/pleroma/pleroma.git . && \
    git checkout ${PLEROMA_VERSION} && \
    ls -la config/ && \
    chown -R pleroma:pleroma /opt/pleroma

# Install Hex and Rebar
USER pleroma
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
RUN mix deps.get --only prod

# Compile the application
RUN MIX_ENV=prod mix compile

# Runtime stage
FROM alpine:3.21

# Install runtime dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache \
    erlang \
    elixir \
    postgresql-client \
    file \
    imagemagick \
    ffmpeg \
    exiftool \
    curl \
    git \
    ca-certificates

# Create pleroma user
RUN addgroup pleroma && \
    adduser -S -s /bin/false -h /opt/pleroma -H -G pleroma pleroma

# Create directories for overlay filesystem and init scripts (as root)
RUN mkdir -p /config-overlay/upper /config-overlay/work /docker-entrypoint-init.d && \
    chown -R pleroma:pleroma /config-overlay

# Create init script for overlay mount
RUN echo '#!/bin/sh\n\
# Create overlay mount for config directory\n\
if [ -d "/config" ]; then\n\
  echo "Setting up overlay filesystem for config..."\n\
  mount -t overlay overlay \\\n\
    -o lowerdir=/opt/pleroma/config,upperdir=/config,workdir=/config-overlay/work \\\n\
    /opt/pleroma/config\n\
fi' > /docker-entrypoint-init.d/01-config-overlay.sh && \
    chmod +x /docker-entrypoint-init.d/01-config-overlay.sh

# Copy and set up entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy built application from builder stage
COPY --from=builder --chown=pleroma:pleroma /opt/pleroma /opt/pleroma

# Set working directory
WORKDIR /opt/pleroma

# Switch to pleroma user
USER pleroma

# Install Hex and Rebar for runtime
RUN mix local.hex --force && \
    mix local.rebar --force

# Create directories for uploads and static files
RUN mkdir -p uploads && \
    mkdir -p static

# Switch back to root for startup script
USER root

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/api/v1/instance || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []

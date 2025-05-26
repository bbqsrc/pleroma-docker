# Pleroma Docker Setup

This repository contains a Docker setup for Pleroma based on the [official Alpine Linux installation guide](https://docs.pleroma.social/backend/installation/alpine_linux_en/).

## Prerequisites

- Docker and Docker Compose installed
- A domain name pointing to your server
- SSL certificates (Let's Encrypt recommended)

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url>
   cd pleroma-docker
   ```

2. **Create the config directory:**
   ```bash
   mkdir -p config
   ```

3. **Build with specific Pleroma version (optional):**
   ```bash
   # Option 1: Set environment variable
   export PLEROMA_VERSION=v2.6.2
   
   # Option 2: Create a .env file
   echo "PLEROMA_VERSION=v2.6.2" > .env
   
   # Available versions:
   # - stable (default)
   # - develop 
   # - v2.6.2 (or any other tag)
   # - commit hash (e.g., abc123def456)
   ```

4. **Generate Pleroma configuration:**
   ```bash
   # Run the configuration generator
   docker-compose run --rm pleroma mix pleroma.instance gen
   
   # Move the generated config
   docker-compose run --rm pleroma mv config/generated_config.exs config/prod.secret.exs
   ```

5. **Update nginx configuration:**
   - Edit `nginx.conf` and replace `your.domain` with your actual domain
   - Update SSL certificate paths in the nginx configuration
   - Place your SSL certificates in the `ssl/` directory

6. **Start the services:**
   ```bash
   docker-compose up -d
   ```

7. **Create your first admin user:**
   ```bash
   docker-compose exec pleroma mix pleroma.user new <username> <your@email.com> --admin
   ```

## Configuration

### Environment Variables

The following environment variables can be configured in `docker-compose.yml`:

- `POSTGRES_USER`: PostgreSQL username (default: pleroma)
- `POSTGRES_PASSWORD`: PostgreSQL password (default: pleroma)
- `POSTGRES_DB`: PostgreSQL database name (default: pleroma)
- `DATABASE_URL`: Database connection URL
- `MIX_ENV`: Elixir environment (default: prod)

### Build Arguments

- `PLEROMA_VERSION`: Pleroma version to build (default: stable)
  - Can be a git branch: `stable`, `develop`
  - Can be a git tag: `v2.6.2`, `v2.5.4`
  - Can be a commit hash: `abc123def456`

### Pleroma Configuration

The Pleroma configuration is stored in the `config/` directory. Key files:

- `config/prod.secret.exs`: Main production configuration
- `config/setup_db.psql`: Database setup script (auto-generated)

### SSL/TLS Setup

1. **Using Let's Encrypt:**
   ```bash
   # Install certbot
   sudo apt-get install certbot
   
   # Get certificates
   sudo certbot certonly --standalone -d your.domain
   
   # Copy certificates to ssl directory
   sudo cp /etc/letsencrypt/live/your.domain/* ./ssl/
   ```

2. **Update nginx.conf with correct certificate paths**

## Services

### Pleroma
- **Port:** 4000 (internal), proxied through nginx
- **Health check:** `/api/v1/instance` endpoint
- **Volumes:** 
  - `pleroma_uploads`: User uploads
  - `pleroma_static`: Static files
  - `./config`: Configuration files

### PostgreSQL
- **Port:** 5432 (internal only)
- **Database:** pleroma
- **Volume:** `postgres_data`

### Nginx
- **Ports:** 80 (HTTP), 443 (HTTPS)
- **Configuration:** `./nginx.conf`
- **SSL certificates:** `./ssl/`

## Management Commands

### Database Operations
```bash
# Run database migrations
docker-compose exec pleroma mix ecto.migrate

# Create database backup
docker-compose exec db pg_dump -U pleroma pleroma > backup.sql

# Restore database backup
docker-compose exec -T db psql -U pleroma pleroma < backup.sql
```

### User Management
```bash
# Create a new user
docker-compose exec pleroma mix pleroma.user new <username> <email>

# Make user admin
docker-compose exec pleroma mix pleroma.user set <username> --admin

# Delete user
docker-compose exec pleroma mix pleroma.user rm <username>
```

### Instance Management
```bash
# View logs
docker-compose logs -f pleroma

# Restart services
docker-compose restart

# Build with specific version
export PLEROMA_VERSION=v2.6.2
docker-compose build --no-cache pleroma

# Update Pleroma
docker-compose pull
docker-compose up -d --build
```

## Troubleshooting

### Common Issues

1. **Database connection errors:**
   - Ensure PostgreSQL is healthy: `docker-compose ps`
   - Check database credentials in configuration

2. **SSL certificate errors:**
   - Verify certificate paths in `nginx.conf`
   - Ensure certificates are readable by nginx container

3. **Permission errors:**
   - Check file ownership: `sudo chown -R 1000:1000 config/`

### Logs
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs pleroma
docker-compose logs db
docker-compose logs nginx
```

## Security Considerations

1. **Change default passwords** in `docker-compose.yml`
2. **Use strong SSL configuration** (already configured in nginx.conf)
3. **Regular updates** of Docker images and Pleroma
4. **Firewall configuration** to restrict access to necessary ports only
5. **Regular backups** of database and configuration

## Updating

To update Pleroma:

1. **Backup your data:**
   ```bash
   docker-compose exec db pg_dump -U pleroma pleroma > backup-$(date +%Y%m%d).sql
   ```

2. **Pull latest changes:**
   ```bash
   git pull origin main
   ```

3. **Rebuild and restart:**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. **Run migrations:**
   ```bash
   docker-compose exec pleroma mix ecto.migrate
   ```

## Support

For support and questions:
- [Pleroma Documentation](https://docs.pleroma.social/)
- [Pleroma Matrix Channel](https://matrix.to/#/#pleroma:libera.chat)
- [Pleroma IRC Channel](https://web.libera.chat/#pleroma) (#pleroma on libera.chat)

## License

This Docker setup is provided as-is. Pleroma itself is licensed under the AGPL v3. 
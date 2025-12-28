# FastAPI Docker Demo

A complete FastAPI application with PostgreSQL database, nginx-proxy, and automatic SSL certificates.

## Features

- **FastAPI Backend** with PostgreSQL database
- **Automatic SSL** certificates via Let's Encrypt
- **nginx-proxy** for reverse proxy and load balancing
- **Supervisord** for process management
- **Automated backups** with cron jobs
- **Docker Compose** for easy deployment

## Quick Start

### Local Development

1. **Clone the repository:**

   ```bash
   git clone https://github.com/varadhan06/fast-demo.git
   cd fast-demo
   ```

2. **Start the application:**

   ```bash
   docker compose up -d
   ```

3. **Initialize the database:**

   ```bash
   docker compose exec backend python setup.py
   ```

4. **Access the application:**
   - API: `http://localhost/status`
   - Docs: `http://localhost/docs`

### AWS EC2 Deployment

Use this user data script when launching an EC2 instance:

```bash
#!/bin/bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt install docker-compose-plugin -y
sudo apt install git -y

# Clone and start the application
cd /home/ubuntu/
git clone https://github.com/varadhan06/fast-demo.git
cd fast-demo
docker compose up -d
sleep 30
docker compose exec backend python setup.py

# Setup automated backups
mkdir -p /home/ubuntu/backups
chmod 700 /home/ubuntu/backups

cat > /home/ubuntu/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
CONTAINER_NAME="demo_1_db"
DB_NAME="devops_docker_demo_1"
DB_USER="postgres"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

docker exec $CONTAINER_NAME pg_dump -U $DB_USER -d $DB_NAME > $BACKUP_FILE
gzip $BACKUP_FILE
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
EOF

chmod +x /home/ubuntu/backup-db.sh
echo "0 2 * * * /home/ubuntu/backup-db.sh" | crontab -
```

## API Endpoints

- `GET /status` - Health check
- `GET /movies` - List all movies
- `GET /movie/{id}` - Get specific movie
- `GET /users` - List all users
- `POST /users` - Create new user
- `PUT /user/{id}` - Update user
- `DELETE /user/{id}` - Delete user
- `POST /reviews` - Create movie review

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   nginx-proxy   │────│   FastAPI    │────│   PostgreSQL   │
│   (Port 80/443) │    │   Backend    │    │   Database      │
│   + SSL Certs   │    │ (Supervisord)│    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## Process Management

The application uses **supervisord** to manage multiple processes:

```bash
# Check process status
docker compose exec backend supervisorctl status

# Restart FastAPI
docker compose exec backend supervisorctl restart fastapi

# View logs
docker compose exec backend cat /var/log/supervisor/fastapi.out.log
```

## Database Backups

Automated daily backups at 2 AM:

- Location: `/home/ubuntu/backups/`
- Retention: 7 days
- Format: Compressed SQL dumps

## Environment Variables

| Variable            | Description                | Default                 |
| ------------------- | -------------------------- | ----------------------- |
| `DATABASE`          | Database name              | `devops_docker_demo_1`  |
| `PASSWORD`          | Database password          | `postgres123`           |
| `DB_HOST`           | Database host              | `db`                    |
| `DB_PORT`           | Database port              | `5432`                  |
| `VIRTUAL_HOST`      | Domain for nginx-proxy     | `api.vty.life`          |
| `LETSENCRYPT_EMAIL` | Email for SSL certificates | `servicevg06@gmail.com` |

## Development

### Adding New Dependencies

1. Update `api/requirements.txt`
2. Rebuild: `docker compose up --build`

### Database Migrations

```bash
# Run setup script
docker compose exec backend python setup.py

# Connect to database
docker compose exec db psql -U postgres -d devops_docker_demo_1
```

## Troubleshooting

### Check Container Status

```bash
docker compose ps
```

### View Logs

```bash
docker compose logs backend
docker compose logs db
docker compose logs nginx-proxy
```

### Test Database Connection

```bash
docker compose exec backend python -c "from setup import get_connection; print('DB OK' if get_connection() else 'DB Error')"
```

### To create ssh user.

cd scripts

chmod +x create_ssh_user.sh

sudo ./create_ssh_user.sh YOURUSERNAME "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBexamplekey user@laptop"

## Security Notes

- Database is not exposed publicly (no external ports)
- Uses non-root user in containers
- SSL certificates automatically managed
- Environment variables contain sensitive data (change for production)

## License

MIT License

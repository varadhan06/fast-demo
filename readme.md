1. Rename .env.example to .env
2. Add a dockerignore file later

# Testing Supervisord

docker compose exec backend supervisorctl status

# Check supervisord main log

docker compose exec backend cat /var/log/supervisor/supervisord.log

# Check FastAPI logs

docker compose exec backend cat /var/log/supervisor/fastapi.out.log

# Check worker logs

docker compose exec backend cat /var/log/supervisor/worker.out.log

# Kill the FastAPI process

docker compose exec backend supervisorctl stop fastapi

# Check status (should show STOPPED)

docker compose exec backend supervisorctl status

# Restart it

docker compose exec backend supervisorctl start fastapi

# Verify it's running again

docker compose exec backend supervisorctl status

# Find the FastAPI process PID

docker compose exec backend supervisorctl status

# Kill it by PID (supervisord should restart it automatically)

docker compose exec backend kill -9 <PID>

# Check status - should show RUNNING again with new PID

docker compose exec backend supervisorctl status

# Test the API endpoint

curl http://localhost/status

# or

curl http://YOUR_IP/status

docker compose logs -f backend

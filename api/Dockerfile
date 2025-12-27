# BASE IMAGE
FROM python:3.12-slim

WORKDIR /api

# Install supervisor and create log directory
RUN apt-get update && apt-get install -y supervisor  procps && \
    mkdir -p /var/log/supervisor && \
    rm -rf /var/lib/apt/lists/*

# Copy only requirements first for better layer caching
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and supervisor config
COPY . .
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create non-root user for security
RUN adduser --uid 1000 apiuser && chown -R apiuser:apiuser /api

EXPOSE 8000

# Use supervisord as the main process
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
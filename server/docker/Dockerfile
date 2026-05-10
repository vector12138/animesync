# Backend Dockerfile for AnimeSync
# Build context should be the project root (../)
# Usage in docker-compose: build: context: ., dockerfile: docker/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# Install build dependencies and PostgreSQL client library
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY server/ /app/

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 8000

# Run the server
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
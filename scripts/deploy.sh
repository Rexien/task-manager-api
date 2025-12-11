#!/bin/bash

# Stop script on error
set -e

echo "🚀 Starting Deployment..."

# 1. Pull latest code (if running on server from git)
# git pull origin main

# 2. Pull latest images
echo "📥 Pulling Docker images..."
docker-compose pull

# 3. Start services
echo "🔄 Restarting services..."
docker-compose up -d --remove-orphans

# 4. Run migrations
echo "🗄️ Running database migrations..."
docker-compose exec -T web flask db upgrade

echo "✅ Deployment Complete!"

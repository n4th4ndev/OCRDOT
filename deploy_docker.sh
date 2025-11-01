#!/bin/bash

# DocStrange Docker Deployment Script
# For VPS with GPU support

set -e

echo "🐳 DocStrange Docker Deployment Script"
echo "======================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and back in."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Check if NVIDIA Docker is installed
if ! docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
    echo "⚠️  NVIDIA Docker runtime not detected."
    echo "Installing NVIDIA Docker support..."
    
    # Install nvidia-docker2
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    
    sudo apt-get update
    sudo apt-get install -y nvidia-docker2
    sudo systemctl restart docker
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p models logs ssl

# Create nginx configuration
echo "🌐 Creating Nginx configuration..."
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream docstrange {
        server docstrange:8000;
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://docstrange;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Increase timeouts for model loading
            proxy_connect_timeout 300s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
}
EOF

# Build and start services
echo "🔨 Building DocStrange Docker image..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Test the application
echo "🧪 Testing application..."
if curl -f http://localhost:8000/api/health; then
    echo "✅ DocStrange is running successfully!"
else
    echo "❌ DocStrange failed to start. Checking logs..."
    docker-compose logs docstrange
fi

echo ""
echo "🎉 Docker Deployment Complete!"
echo "============================="
echo "DocStrange is now running on:"
echo "  - Local: http://localhost:8000"
echo "  - External: http://$(curl -s ifconfig.me):8000"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Restart: docker-compose restart"
echo "  - Stop: docker-compose down"
echo "  - Update: docker-compose pull && docker-compose up -d"
echo ""
echo "🔧 First-time model download will happen on first request."
echo "This may take a few minutes depending on your connection."

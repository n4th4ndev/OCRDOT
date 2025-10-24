# DocStrange VPS Deployment Guide

## 🚀 Quick Start

### Option 1: Direct Installation (Recommended)
```bash
# Make the script executable
chmod +x deploy_vps.sh

# Run the deployment script
./deploy_vps.sh
```

### Option 2: Docker Deployment
```bash
# Make the script executable
chmod +x deploy_docker.sh

# Run the Docker deployment
./deploy_docker.sh
```

## 📋 Prerequisites

### VPS Requirements
- **OS**: Ubuntu 22.04 LTS (recommended)
- **RAM**: Minimum 16GB (32GB recommended)
- **Storage**: Minimum 50GB SSD
- **GPU**: NVIDIA GPU with CUDA support
- **CUDA**: Version 12.2 or compatible

### System Requirements
- Python 3.11+
- CUDA Toolkit 12.2+
- Docker (for Docker deployment)
- NVIDIA Docker runtime (for GPU support)

## 🔧 Manual Installation

### 1. System Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.11
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev

# Install CUDA (if not already installed)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-2
```

### 2. Install Dependencies
```bash
# Install system dependencies
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install PyTorch with CUDA
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install other dependencies
pip install -r requirements_vps.txt
```

### 3. Deploy Application
```bash
# Install DocStrange
pip install -e .

# Create systemd service
sudo tee /etc/systemd/system/docstrange.service > /dev/null <<EOF
[Unit]
Description=DocStrange Web Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
ExecStart=$(pwd)/venv/bin/python -m docstrange web --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable docstrange
sudo systemctl start docstrange
```

## 🐳 Docker Deployment

### 1. Install Docker and NVIDIA Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install NVIDIA Docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### 2. Deploy with Docker Compose
```bash
# Build and start
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## 🔍 Monitoring and Maintenance

### Check Service Status
```bash
# Systemd service
sudo systemctl status docstrange
sudo journalctl -u docstrange -f

# Docker service
docker-compose ps
docker-compose logs -f
```

### Monitor Resources
```bash
# GPU usage
nvidia-smi

# Memory usage
free -h

# Disk usage
df -h

# CPU usage
htop
```

### Update Application
```bash
# Systemd deployment
cd /opt/docstrange
git pull
source venv/bin/activate
pip install --upgrade -e .
sudo systemctl restart docstrange

# Docker deployment
docker-compose pull
docker-compose up -d
```

## 🌐 Nginx Configuration (Optional)

### Basic Reverse Proxy
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
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
```

### SSL with Let's Encrypt
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔧 Troubleshooting

### Common Issues

1. **CUDA not detected**
   ```bash
   nvidia-smi  # Check if GPU is visible
   python -c "import torch; print(torch.cuda.is_available())"  # Check PyTorch CUDA
   ```

2. **Model loading fails**
   ```bash
   # Check disk space
   df -h
   
   # Check memory
   free -h
   
   # Check logs
   sudo journalctl -u docstrange -f
   ```

3. **Service won't start**
   ```bash
   # Check service status
   sudo systemctl status docstrange
   
   # Check logs
   sudo journalctl -u docstrange --no-pager
   
   # Test manually
   source venv/bin/activate
   python -m docstrange web
   ```

### Performance Optimization

1. **GPU Memory Optimization**
   ```python
   # In local_nanonets_processor.py
   torch.cuda.empty_cache()  # Clear GPU cache
   ```

2. **Model Quantization**
   ```python
   # Use 8-bit quantization for smaller memory footprint
   model = AutoModelForImageTextToText.from_pretrained(
       model_path,
       load_in_8bit=True,
       device_map="auto"
   )
   ```

3. **Batch Processing**
   ```python
   # Process multiple documents in batches
   for batch in document_batches:
       results = model.process_batch(batch)
   ```

## 📊 Monitoring Scripts

### System Monitor
```bash
#!/bin/bash
# monitor.sh
echo "DocStrange Status:"
sudo systemctl status docstrange --no-pager
echo ""
echo "GPU Status:"
nvidia-smi
echo ""
echo "Memory Usage:"
free -h
echo ""
echo "Disk Usage:"
df -h
```

### Health Check
```bash
#!/bin/bash
# health_check.sh
curl -f http://localhost:8000/api/health || {
    echo "Service is down, restarting..."
    sudo systemctl restart docstrange
}
```

## 🚀 Production Recommendations

1. **Use a reverse proxy** (Nginx/Apache)
2. **Enable SSL/TLS** for secure connections
3. **Set up monitoring** (Prometheus/Grafana)
4. **Configure log rotation**
5. **Set up automated backups**
6. **Use a process manager** (PM2/systemd)
7. **Monitor resource usage**
8. **Set up alerts** for failures

## 📞 Support

For issues and support:
- Check logs: `sudo journalctl -u docstrange -f`
- Monitor resources: `nvidia-smi`, `htop`, `df -h`
- Test manually: `python -m docstrange web`
- Check network: `curl http://localhost:8000/api/health`

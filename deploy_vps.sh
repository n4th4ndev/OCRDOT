#!/bin/bash

# DocStrange VPS Deployment Script
# Optimized for VPS with GPU (CUDA)

set -e

echo "🚀 DocStrange VPS Deployment Script"
echo "======================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python 3.11
echo "🐍 Installing Python 3.11..."
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Install CUDA (if not already installed)
echo "🎮 Checking CUDA installation..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "⚠️  CUDA not detected. Installing CUDA..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt update
    sudo apt install -y cuda-toolkit-12-2
    echo "✅ CUDA installed. Please reboot if this is the first CUDA installation."
fi

# Install system dependencies
echo "📚 Installing system dependencies..."

# Check Ubuntu version and install appropriate packages
UBUNTU_VERSION=$(lsb_release -rs)
echo "Detected Ubuntu version: $UBUNTU_VERSION"

if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    echo "Installing packages for Ubuntu 24.04 (Noble)..."
    sudo apt install -y \
        build-essential \
        git \
        curl \
        wget \
        unzip \
        libgl1-mesa-dri \
        libglib2.0-0t64 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libgcc-s1 \
        libgl1-mesa-glx-t64
else
    echo "Installing packages for older Ubuntu versions..."
    sudo apt install -y \
        build-essential \
        git \
        curl \
        wget \
        unzip \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libgcc-s1
fi

# Create project directory
echo "📁 Setting up project directory..."
PROJECT_DIR="/opt/docstrange"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Copy project files
echo "📋 Copying project files..."
cp -r . $PROJECT_DIR/
cd $PROJECT_DIR

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install PyTorch with CUDA support
echo "🔥 Installing PyTorch with CUDA support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install other dependencies
echo "📦 Installing Python dependencies..."
pip install \
    transformers \
    accelerate \
    safetensors \
    flask \
    pillow \
    requests \
    PyMuPDF \
    numpy \
    tqdm

# Install DocStrange in development mode
echo "🔧 Installing DocStrange..."
pip install -e .

# Create systemd service
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/docstrange.service > /dev/null <<EOF
[Unit]
Description=DocStrange Web Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/venv/bin
ExecStart=$PROJECT_DIR/venv/bin/python -m docstrange web --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "🚀 Starting DocStrange service..."
sudo systemctl daemon-reload
sudo systemctl enable docstrange
sudo systemctl start docstrange

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow 8000/tcp
sudo ufw --force enable

# Create nginx configuration (optional)
echo "🌐 Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/docstrange > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable nginx site
sudo ln -sf /etc/nginx/sites-available/docstrange /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Create monitoring script
echo "📊 Creating monitoring script..."
tee $PROJECT_DIR/monitor.sh > /dev/null <<EOF
#!/bin/bash
echo "DocStrange Status:"
echo "=================="
echo "Service Status:"
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
EOF

chmod +x $PROJECT_DIR/monitor.sh

# Create update script
echo "🔄 Creating update script..."
tee $PROJECT_DIR/update.sh > /dev/null <<EOF
#!/bin/bash
echo "🔄 Updating DocStrange..."
cd $PROJECT_DIR
source venv/bin/activate
pip install --upgrade -e .
sudo systemctl restart docstrange
echo "✅ Update complete!"
EOF

chmod +x $PROJECT_DIR/update.sh

# Final status check
echo "🔍 Checking deployment status..."
sleep 5
sudo systemctl status docstrange --no-pager

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "DocStrange is now running on:"
echo "  - Local: http://localhost:8000"
echo "  - External: http://$(curl -s ifconfig.me):8000"
echo ""
echo "Useful commands:"
echo "  - Check status: sudo systemctl status docstrange"
echo "  - View logs: sudo journalctl -u docstrange -f"
echo "  - Restart: sudo systemctl restart docstrange"
echo "  - Monitor: $PROJECT_DIR/monitor.sh"
echo "  - Update: $PROJECT_DIR/update.sh"
echo ""
echo "🔧 First-time model download will happen on first request."
echo "This may take a few minutes depending on your connection."

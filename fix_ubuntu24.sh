#!/bin/bash

# Quick fix for Ubuntu 24.04 package issues
echo "🔧 Fixing Ubuntu 24.04 package issues..."

# Update package lists
sudo apt update

# Install the correct packages for Ubuntu 24.04
echo "📦 Installing correct packages for Ubuntu 24.04..."
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
    libgl1-mesa-glx-t64 \
    libglib2.0-0 \
    libgl1-mesa-glx

echo "✅ Package installation completed!"
echo "You can now continue with the deployment."

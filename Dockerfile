# DocStrange Dockerfile for VPS with GPU
FROM nvidia/cuda:12.2-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
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
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements_vps.txt .

# Create virtual environment and install dependencies
RUN python3.11 -m venv venv
RUN . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    pip install -r requirements_vps.txt

# Copy application code
COPY . .

# Install DocStrange
RUN . venv/bin/activate && pip install -e .

# Create non-root user
RUN useradd -m -u 1000 docstrange && \
    chown -R docstrange:docstrange /app
USER docstrange

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

# Run the application
CMD ["/app/venv/bin/python", "-m", "docstrange", "web", "--host", "0.0.0.0", "--port", "8000"]

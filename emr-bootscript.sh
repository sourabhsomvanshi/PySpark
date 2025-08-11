#!/bin/bash

# EMR Bootstrap Script for Amazon Linux 2023
# Compatible with EMR 7.9.0

set -e  # Exit on any error
set -x  # Print commands as they execute

# Update packages using dnf (AL2023 package manager)
sudo dnf update -y

# Install required dependencies
sudo dnf install -y python3-devel gcc python3-pip

# Install additional development tools that might be needed
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y openssl-devel bzip2-devel libffi-devel sqlite-devel

# Check if Python 3.8 is available via dnf
if sudo dnf list available python3.8 &>/dev/null; then
    echo "Installing Python 3.8 via dnf..."
    sudo dnf install -y python3.8 python3.8-pip
    PYTHON38_PATH="/usr/bin/python3.8"
else
    echo "Python 3.8 not available via dnf, building from source..."
    
    # Download and compile Python 3.8 from source
    cd /tmp
    wget https://www.python.org/ftp/python/3.8.18/Python-3.8.18.tgz
    tar xzf Python-3.8.18.tgz
    cd Python-3.8.18
    
    # Configure and build Python 3.8
    ./configure --enable-optimizations --prefix=/usr/local
    make -j$(nproc)
    sudo make altinstall
    
    PYTHON38_PATH="/usr/local/bin/python3.8"
    
    # Create symlink for easier access
    sudo ln -sf /usr/local/bin/python3.8 /usr/bin/python3.8
    sudo ln -sf /usr/local/bin/pip3.8 /usr/bin/pip3.8
    
    # Clean up
    cd /tmp
    rm -rf Python-3.8.18*
fi

# Verify Python 3.8 installation
$PYTHON38_PATH --version

# Set environment variables for all users and sessions
# Add to system-wide profile
sudo tee /etc/profile.d/spark-python.sh > /dev/null <<EOF
export PYSPARK_PYTHON=$PYTHON38_PATH
export PYSPARK_DRIVER_PYTHON=$PYTHON38_PATH
export SPARK_HOME=/usr/lib/spark
export PATH=\$PATH:\$SPARK_HOME/bin
EOF

# Make the profile script executable
sudo chmod +x /etc/profile.d/spark-python.sh

# Also add to current user's bashrc for immediate effect
echo "export PYSPARK_PYTHON=$PYTHON38_PATH" >> ~/.bashrc
echo "export PYSPARK_DRIVER_PYTHON=$PYTHON38_PATH" >> ~/.bashrc
echo "export SPARK_HOME=/usr/lib/spark" >> ~/.bashrc
echo "export PATH=\$PATH:\$SPARK_HOME/bin" >> ~/.bashrc

# For hadoop user (if exists)
if id "hadoop" &>/dev/null; then
    sudo -u hadoop bash -c "echo 'export PYSPARK_PYTHON=$PYTHON38_PATH' >> ~hadoop/.bashrc"
    sudo -u hadoop bash -c "echo 'export PYSPARK_DRIVER_PYTHON=$PYTHON38_PATH' >> ~hadoop/.bashrc"
    sudo -u hadoop bash -c "echo 'export SPARK_HOME=/usr/lib/spark' >> ~hadoop/.bashrc"
    sudo -u hadoop bash -c "echo 'export PATH=\$PATH:\$SPARK_HOME/bin' >> ~hadoop/.bashrc"
fi

# Load the updated environment
source ~/.bashrc || true
source /etc/profile.d/spark-python.sh || true

# Install pip for Python 3.8 if not already available
if ! command -v pip3.8 &> /dev/null; then
    $PYTHON38_PATH -m ensurepip --upgrade
fi

# Upgrade pip to latest version
$PYTHON38_PATH -m pip install --upgrade pip

# Install Pandas 1.5.3 with dependencies
$PYTHON38_PATH -m pip install pandas==1.5.3

# Install other commonly needed packages for Spark/EMR
$PYTHON38_PATH -m pip install numpy==1.24.3 pyarrow==12.0.1

# Verify installations
echo "Verifying installations..."
$PYTHON38_PATH -c "import pandas; print(f'Pandas version: {pandas.__version__}')"
$PYTHON38_PATH -c "import numpy; print(f'Numpy version: {numpy.__version__}')"
$PYTHON38_PATH -c "import pyarrow; print(f'PyArrow version: {pyarrow.__version__}')"

echo "Bootstrap script completed successfully!"

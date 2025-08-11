#!/bin/bash

# Update packages
sudo yum update -y

# Install required dependencies
sudo yum install -y python3-devel gcc

# Install Python 3.8
sudo amazon-linux-extras install python3.8

# Set PYSPARK_PYTHON and PYSPARK_DRIVER_PYTHON to Python 3.8
echo 'export PYSPARK_PYTHON=/usr/bin/python3.8' >> ~/.bashrc
echo 'export PYSPARK_DRIVER_PYTHON=/usr/bin/python3.8' >> ~/.bashrc

# Set environment variables
echo 'export SPARK_HOME=/usr/lib/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin' >> ~/.bashrc

# Load the updated bashrc
source ~/.bashrc || true

# Install Pandas 1.5.3
pip3.8 install pandas==1.5.3

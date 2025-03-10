#!/bin/bash
set -e

# Create directory structure for the layer
mkdir -p pandas_layer/python

# Check Python version
PYTHON_CMD="python"
PYTHON_VERSION=$($PYTHON_CMD --version)
echo "Using $PYTHON_VERSION"

# Create a temporary virtual environment
$PYTHON_CMD -m venv venv
source venv/Scripts/activate  # Modified for Windows

# Install pandas with minimal dependencies
pip install pandas pyarrow --no-deps
pip install numpy --no-deps
pip install python-dateutil --no-deps
pip install pytz --no-deps
pip install six --no-deps

# Copy the installed packages to the layer directory
cp -r venv/Lib/site-packages/* pandas_layer/python/  # Modified for Windows Python directory structure

# Clean up
deactivate
rm -rf venv

echo "Pandas layer prepared successfully."
# macsoft_drip_irrigation
cd ~/raspberry_pi

# Remove the copied venv (if you used Option 2)
rm -rf venv

# Create a fresh virtual environment on the Pi
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install the dependencies
pip3 install paho-mqtt pyserial

# Run the script
python3 master.py

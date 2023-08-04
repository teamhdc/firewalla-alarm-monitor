#!/bin/bash

# Install Vector
curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash -s -- -y

# Make vector data directory
mkdir /home/pi/.vector/data

# Create main vector config
cat <<EOF > /home/pi/.vector/config/vector.toml
data_dir = "/home/pi/.vector/data"
EOF

# Create Vector azure config
cat <<EOF > /home/pi/.vector/config/azure.toml
[sources.firelog]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/firelog.log" ]
    read_from = "beginning"

[sources.fireapi]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/FireApi.log" ]
    read_from = "beginning"

[sources.firekick]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/FireKick.log" ]
    read_from = "beginning"

[sources.firemain]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/FireMain.log" ]
    read_from = "beginning"

[sources.firemon]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/FireMon.log" ]
    read_from = "beginning"

[sources.firerouter]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/FireRouter.log" ]
    read_from = "beginning"
    
[sources.firetrace]
    type = "file"
    ignore_older_secs = 600
    include = [ "/home/pi/logs/Trace.log" ]
    read_from = "beginning"

[sinks.azure_sync]
type = "azure_monitor_logs"
inputs = [ "firelog" ]
customer_id = "$WORKSPACE_ID"
log_type = "firewalla"
shared_key = "$WORKSPACE_SECRET"
EOF

# Install python dependencies
sudo apt update -y
sudo apt install -y python3.8-venv
python3 -m venv venv
./venv/bin/pip install paho-mqtt redis

# Update ca certificates
sudo update-ca-certificates

# Create environment for service
sudo tee /etc/default/fam <<EOF
MQTT_BROKER=$MQTT_BROKER
MQTT_USERNAME=$MQTT_USERNAME
MQTT_PASSWORD=$MQTT_PASSWORD
EOF

# Create systemd service
sudo tee /etc/systemd/system/fam.service <<EOF
[Unit]
Description=Firewalla Alarm Monitor
After=network.target

[Service]
ExecStart=/home/pi/hdc-alarm-monitor/venv/bin/python /home/pi/hdc-alarm-monitor/main.py
WorkingDirectory=/home/pi/hdc-alarm-monitor
User=pi
Group=pi
Restart=always
Environment=/etc/default/fam

[Install]
WantedBy=multi-user.target
EOF
#!/usr/bin/env bash

logger "Starting bedrock.sh..."

MINECRAFT_HOME_DIR=/home/minecraft
MINECRAFT_BEDROCK_DIR=$MINECRAFT_HOME_DIR/bedrock_server

# Creates Minecraft service user account
logger "Adding minecraft service user account..."

sudo adduser --disabled-password --gecos 'User for running and managing Minecraft servers' minecraft
sudo echo "minecraft     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Updates packages, installs dependencies
sudo apt update
sudo apt install wget unzip git screen lsof -y

# Download and unzip the Minecraft bedrock server zip
logger "Starting download and unpackaging of minecraft bedrock server..."

cd $MINECRAFT_HOME_DIR
mkdir bedrock_server

# TODO: Make this dynamic?
DOWNLOAD_URL="https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.3.01.zip"

sudo wget $DOWNLOAD_URL -O $MINECRAFT_BEDROCK_DIR/bedrock-server.zip

sudo unzip $MINECRAFT_BEDROCK_DIR/bedrock-server.zip -d $MINECRAFT_BEDROCK_DIR

# Clean up the left over zip file
sudo rm $MINECRAFT_BEDROCK_DIR/bedrock-server.zip

# Change owner so that the `minecraft` service account can manipulate files
sudo chown -R minecraft:minecraft $MINECRAFT_HOME_DIR

# Create service for Minecraft Bedrock server
# Pulls in eula & server.properties
git clone https://github.com/jacob-howe/mc-server.git

# Tests that mc-server was cloned successfully
GIT_CLONE_CHECK=$(ls $MINECRAFT_HOME_DIR | wc -l)
if [ $GIT_CLONE_CHECK -gt 1 ]; then
    logger "Minecraft Bedrock server files were cloned successfully."
else
    logger "Unable to clone Minecraft Bedrock server files"
    exit 1
fi

# Create service for Minecraft Bedrock Server
sudo echo '[Unit]
Description=Minecraft Bedrock Server
Wants=network-online.target
After=network-online.target

[Service]
Type=forking
User=minecraft
Group=minecraft
ExecStart=/usr/bin/bash /home/minecraft/mc-server/bedrock/start_server.sh
ExecStop=/usr/bin/bash /home/minecraft/mc-server/bedrock/stop_server.sh
WorkingDirectory=/home/minecraft/bedrock_server/
Restart=always
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/minecraft.service

# Create service for Player Checker
sudo echo '[Unit]
Description=Checks for online players
Wants=network.target
After=local-fs.target network.target minecraft.service

[Service]
User=minecraft
Group=minecraft
UMask=0027

KillMode=none
SuccessExitStatus=0 1 255

ExecStart=/home/minecraft/mc-server/bedrock/player_check.sh

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/player_check.service

# Grant execution permissions to *_server.sh
sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/bedrock/start_server.sh
sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/bedrock/stop_server.sh
sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/bedrock/player_check.sh

# Set permissions on minecraft.service
sudo chmod 644 /etc/systemd/system/minecraft.service
sudo chmod 644 /etc/systemd/system/player_check.service

# Enable the service
sudo systemctl enable minecraft
sudo systemctl enable player_check

# Start the services
sudo systemctl start minecraft
sudo systemctl start player_check

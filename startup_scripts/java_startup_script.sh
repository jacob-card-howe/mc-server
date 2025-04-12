#!/usr/bin/env bash

set -e

logger "Starting Minecraft Java Server Installation Script..."

MINECRAFT_HOME_DIR=/home/minecraft
MINECRAFT_JAVA_DIR=$MINECRAFT_HOME_DIR/java_server

# Java Server v1.21.5 Server Download URL
DOWNLOAD_URL="https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar"

# Checks to see if Minecraft has already been installed or not.
if [ -d $MINECRAFT_JAVA_DIR ]; then
    logger "Installation has likely already occurred, skipping."
    exit 0
else
    logger "Starting installation..."
    # Creates Minecraft service user account
    logger "Adding minecraft service user account..."

    sudo adduser --disabled-password --gecos 'User for running and managing Minecraft servers' minecraft
    sudo echo "minecraft     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

    # Updates packages, installs dependencies
    sudo apt update
    sudo apt install openjdk-17-jre-headless -y # Installs java

    # Tests that Java was installed successfully and is executable
    if ! [ -x "$(command -v java)" ]; then
        logger "Java was not installed, exiting."
        exit 1
    else
        logger "Java was installed successfully."
    fi

    # Download and unzip the Minecraft java server zip
    logger "Starting download and unpackaging of minecraft java server..."

    cd $MINECRAFT_HOME_DIR
    mkdir java_server

    sudo wget $DOWNLOAD_URL -O $MINECRAFT_JAVA_DIR/server.jar

    sudo chown -R minecraft:minecraft $MINECRAFT_HOME_DIR

    logger "Cloning jacob-card-howe/mc-server for helper scripts..."
    git clone https://github.com/jacob-card-howe/mc-server.git

    # Tests that mc-server was cloned successfully
    GIT_CLONE_CHECK=$(ls $MINECRAFT_HOME_DIR | wc -l)
    if [ $GIT_CLONE_CHECK -gt 1 ]; then
        logger "Minecraft Java server helper files were cloned successfully."
    else
        logger "Unable to clone Minecraft Java server helper files."
        exit 1
    fi

    # Copies the server.properties file, and the eula.txt file to the java_server directory
    logger "Copying server.properties and eula.txt to java_server directory..."
    sudo cp $MINECRAFT_HOME_DIR/mc-server/java/server.properties $MINECRAFT_JAVA_DIR/server.properties
    sudo cp $MINECRAFT_HOME_DIR/mc-server/java/eula.txt $MINECRAFT_JAVA_DIR/eula.txt

    # Creates service for Minecraft Java Server that runs on startup
    logger "Creating Minecraft Java Server service..."

    sudo echo '[Unit]
    Description=Minecraft Java Server
    Wants=network-online.target
    After=network-online.target

    [Service]
    Type=forking
    User=minecraft
    Group=minecraft
    ExecStart=/usr/bin/bash /home/minecraft/mc-server/java/start_server.sh
    ExecStop=/usr/bin/bash /home/minecraft/mc-server/java/stop_server.sh
    WorkingDirectory=/home/minecraft/java_server/
    Restart=always
    TimeoutStartSec=600

    [Install]
    WantedBy=multi-user.target' > /etc/systemd/system/minecraft.service

    # Create service for Player Checker
    logger "Creating Player Checker service..."

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

    ExecStart=/usr/bin/bash /home/minecraft/mc-server/java/player_check.sh

    [Install]
    WantedBy=multi-user.target' > /etc/systemd/system/player_check.service


    logger "Granting executor permissions to Minecraft Java Server bash scripts..."
    sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/java/start_server.sh
    sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/java/stop_server.sh
    sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/java/player_check.sh
    sudo chmod +x $MINECRAFT_HOME_DIR/mc-server/java/service_check.py

    # Set permissions on minecraft.service
    logger "Granting 644 on created services..."
    sudo chmod 644 /etc/systemd/system/minecraft.service
    sudo chmod 644 /etc/systemd/system/player_check.service
    sudo chmod 644 /etc/systemd/system/service_check.service

    # Enable the service
    logger "Enabling services..."
    sudo systemctl enable minecraft
    sudo systemctl enable player_check
    sudo systemctl enable service_check

    # Start the services
    logger "Starting services..."
    sudo systemctl start minecraft
    sleep 120
    # sudo systemctl start player_check
    sudo systemctl start service_check
    exit 0

fi

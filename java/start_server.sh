#!/bin/bash

# Minecraft Server Startup Script
# This script starts a Minecraft Java server with optimized settings

# Configuration
MIN_RAM="2G"  # Minimum RAM allocation
MAX_RAM="7G"  # Maximum RAM allocation
SERVER_JAR="server.jar"  # Server JAR file name
JAVA_PATH="/usr/bin/java"  # Path to Java executable
WORKING_DIR="/home/minecraft/java_server"  # Working directory for the server

if [ -d $WORKING_DIR/world ]; then
    logger "Backing up world..."
    /usr/bin/gcloud storage cp -r $WORKING_DIR/world gs://jch-minecraft-world-backups/java/$(date +"%m-%d-%Y")/session-start/worlds
fi

# Change to the working directory
cd $WORKING_DIR

# Check if server.jar exists
if [ ! -f "$SERVER_JAR" ]; then
    echo "Error: $SERVER_JAR not found in $WORKING_DIR."
    exit 1
fi

# Create eula.txt if it doesn't exist
if [ ! -f "eula.txt" ]; then
    echo "eula=false" > eula.txt
    echo "Please edit eula.txt and set eula=true to accept the Minecraft EULA."
    exit 1
fi

# Check if eula is accepted
if grep -q "eula=false" "eula.txt"; then
    echo "You must accept the Minecraft EULA by setting eula=true in eula.txt"
    exit 1
fi

# Start the server in a screen session
/usr/bin/screen -dmS minecraft_java /bin/bash -c "$JAVA_PATH -Xms$MIN_RAM -Xmx$MAX_RAM -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar $SERVER_JAR nogui"

# Enable multiuser mode and add root access
/usr/bin/screen -rD minecraft_java -X multiuser on
/usr/bin/screen -rD minecraft_java -X acladd root

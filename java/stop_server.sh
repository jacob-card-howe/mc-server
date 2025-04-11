#!/usr/bin/env bash

logger "Stopping minecraft.service..."

MINECRAFT_HOME_DIR=/home/minecraft
MINECRAFT_JAVA_DIR=$MINECRAFT_HOME_DIR/java_server

# Stop the minecraft service gracefully
sudo systemctl stop minecraft

# Wait for the server to fully stop
logger "Waiting for server to stop gracefully..."
sleep 30

# Backup the world data
WORLD_BACKUPS_BUCKET="gs://jch-minecraft-world-backups/java"

logger "Backing up world to $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y")/session-end/world..."

# Backup the world directory
/usr/bin/gcloud storage cp -r $MINECRAFT_JAVA_DIR/world $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y")/session-end/world

# Backup server.properties and other important files
logger "Backing up server configuration files..."
/usr/bin/gcloud storage cp -r $MINECRAFT_JAVA_DIR/server.properties $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y")/session-end/
/usr/bin/gcloud storage cp -r $MINECRAFT_JAVA_DIR/whitelist.json $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y")/session-end/ 2>/dev/null || true
/usr/bin/gcloud storage cp -r $MINECRAFT_JAVA_DIR/ops.json $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y")/session-end/ 2>/dev/null || true

logger "Backup completed. Server stopped successfully."

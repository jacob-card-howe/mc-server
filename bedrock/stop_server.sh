#!/usr/bin/env bash

logger "Stopping minecraft.service..."

MINECRAFT_HOME_DIR=/home/minecraft
MINECRAFT_BEDROCK_DIR=$MINECRAFT_HOME_DIR/bedrock_server

/usr/bin/screen -Rd minecraft_bedrock -X stuff "stop \r"

WORLD_BACKUPS_BUCKET="gs://jch-minecraft-world-backups/bedrock"

logger "Backing up world to $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y-%H:%M:%S")/worlds..."

/usr/bin/gcloud storage cp -r /home/minecraft/bedrock_server/worlds gs://jch-minecraft-world-backups/bedrock/$(date +"%m-%d-%Y-%H:%M:%S")-session-end/worlds

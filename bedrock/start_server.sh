#!/usr/bin/env bash

logger "Starting minecraft.service..."

SERVER_PATH=/home/minecraft/bedrock_server/

logger "Backing up world..."
/usr/bin/gcloud storage cp -r /home/minecraft/bedrock_server/worlds gs://jch-minecraft-world-backups/bedrock/$(date +"%m-%d-%Y-%H:%M:%S")/worlds

/usr/bin/screen -dmS minecraft_bedrock /bin/bash -c "LD_LIBRARY_PATH=$SERVER_PATH ${SERVER_PATH}bedrock_server"
/usr/bin/screen -rD minecraft_bedrock -X multiuser on
/usr/bin/screen -rD minecraft_bedrock -X acladd root

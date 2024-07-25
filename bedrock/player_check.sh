#!/usr/bin/env bash

set -e

cd /home/minecraft/bedrock_server
touch .online_users
touch .start_minecraft

sudo chown -R minecraft:minecraft .

logger "Initializing player_check.sh..."
sleep 120

while true; do
    logger "Player check loop has begun, or started anew!"

    logger "Calculating current number of online users via lsof on port 19132, sleeping for 5 seconds"
    lsof -iTCP:19132 -sTCP:ESTABLISHED > .online_users &
    sleep 5

    logger "Setting current number of online users online by reading .online_users"
    NUMLINES=$(wc -l < .online_users)
    NUMUSERS=$(($NUMLINES - 1))

    logger "Setting max timeout to be 120 seconds"
    TIMEOUTMAX=$((SECONDS+120))

    if [ $NUMUSERS -gt 0 ]
    then
        logger "There are $NUMUSERS online right now! Checking again in 30 seconds..."
        sleep 30
    else
        logger "There are $NUMUSERS online right now, shutting down in 120 seconds unless someone comes online"
        while [ $SECONDS -lt $TIMEOUTMAX ] && [ $NUMUSERS -lt 1 ] ;
        do
            logger "Checking to see if anyone has come online..."
            lsof -iTCP:19132 -sTCP:ESTABLISHED > .online_users &
            sleep 5
            NUMUSERS=$(wc -l < .online_users)
            if [ $NUMUSERS -gt 0 ]
            then
                logger "Someone came online. There are $NUMUSERS players online right now."
                continue 2
            fi
        done
        break
    fi
done


logger "Stopping Minecraft..."
/usr/bin/screen -Rd minecraft_bedrock -X stuff "stop \r"

WORLD_BACKUPS_BUCKET="gs://jch-minecraft-world-backups/bedrock"

logger "Backing up world to $WORLD_BACKUPS_BUCKET/$(date +"%m-%d-%Y-%H:%M:%S")/worlds..."

/usr/bin/gcloud storage cp -r /home/minecraft/bedrock_server/worlds gs://jch-minecraft-world-backups/bedrock/$(date +"%m-%d-%Y-%H:%M:%S")/worlds

logger "Shutting down Server in 1 minute..."
sudo shutdown

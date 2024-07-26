#!/usr/bin/env bash

set -e

cd /home/minecraft/bedrock_server
touch .tcp_dump

sudo chown -R minecraft:minecraft .

logger "Initializing player_check.sh and allowing Minecraft Bedrock server to start..."
sleep 120

while true; do
    logger "Player check loop has begun, or started anew!"

    logger "Calculating current server network traffic on port 19132 via tcpdump, sleeping for 10 seconds"
    sudo timeout "5" tcpdump -i any 'udp port 19132 and dst port 19132' > .tcp_dump &
    sleep 10

    logger "Setting number of recently sent packets by reading .tcp_dump"
    NUMLINES=$(wc -l < .tcp_dump)
    NUMPACKETS=$(($NUMLINES - 1))

    logger "Setting max timeout to be 120 seconds"
    TIMEOUTMAX=$((SECONDS+120))

    if [ $NUMPACKETS -gt 5 ]; then
        logger "There were $NUMPACKETS sent in the last 5 seconds! Checking for traffic again in 30 seconds..."
        sleep 30
    else
        logger "There were $NUMPACKETS sent recently, shutting down in 120 seconds unless someone comes online."
        while [ $SECONDS -lt $TIMEOUTMAX ] && [ $NUMPACKETS -lt 10 ] ;
        do
            logger "Checking to see if anyone has come online..."
            sudo timeout "5" tcpdump -i any 'udp port 19132 and dst port 19132' > .tcp_dump &
            sleep 10
            NUMLINES=$(wc -l < .tcp_dump)
            NUMPACKETS=$(($NUMLINES - 1))
            if [ $NUMPACKETS -gt 5 ]
            then
                logger "Someone came online. There were $NUMPACKETS sent recently."
                continue 2
            fi
        done
        break
    fi
done

sudo systemctl stop minecraft.service

logger "Shutting down Server in 1 minute..."
sudo shutdown

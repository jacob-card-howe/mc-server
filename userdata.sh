#!/bin/bash

# Creates Minecraft service user account
sudo adduser --disabled-password --gecos 'User for running and managing Minecraft servers' minecraft
sudo echo "minecraft     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

sudo apt update # Updates apt repository
sudo apt install openjdk-16-jre-headless -y # Installs java

# Tests that Java was installed successfully and is executable
if ! [ -x "$(command -v java)" ]; then
    logger "Java was not installed, exiting."
    exit 1
else
    logger "Java was installed successfully."
fi

# Change directories into newly created minecraft user's home directory
cd /home/minecraft

# Pulls in eula & server.properties
git clone https://github.com/jacob-howe/mc-server.git

# Tests that mc-server was cloned successfully
GIT_CLONE_CHECK=$(ls | wc -l)
if [ $GIT_CLONE_CHECK -gt 0 ]; then
    logger "Minecraft server files were cloned successfully."
else
    logger "Unable to clone Minecraft server files"
    exit 1
fi

# Change directories into freshly pulled mc-server
cd mc-server/

# Downloads Minecraft Server 1.17.1
wget https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar

# Gives ownership of newly pulled directory to Minecraft user
chown -R minecraft:minecraft .

chmod a+x *.sh

# Creates service for Minecraft Server
sudo echo '[Unit]
Description=A dedicated Minecraft server
Wants=network.target
After=local-fs.target network.target

[Service]
User=minecraft
Group=minecraft
UMask=0027

# EnvironmentFile=/etc/conf.d/minecraft
KillMode=none
SuccessExitStatus=0 1 255

ExecStart=/home/minecraft/start_minecraft.sh
# ExecStop=/usr/bin/mcrcon -H localhost -p ${RCON_PASSWD} stop

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/minecraft.service

# Setting perms on minecraft.service
sudo chmod 644 /etc/systemd/system/minecraft.service

# Creates start up script for Minecraft Server Service
sudo echo '#!/bin/bash
cd /home/minecraft/mc-server
java -Xms1024M -Xmx3072M -XX:ParallelGCThreads=1 -jar server.jar nogui
' > /home/minecraft/start_minecraft.sh

# Creates service for our Player Check
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

ExecStart=/home/minecraft/player_check.sh

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/player_check.service

# Setting perms on player_check.service
sudo chmod 644 /etc/systemd/system/player_check.service

# Creates service for our Service Check
sudo echo '[Unit]
Description=Serves status of Minecraft over port 7777
Wants=network.target
After=local-fs.target network.target minecraft.service

[Service]
User=minecraft
Group=minecraft
UMask=0027

KillMode=none
SuccessExitStatus=0 1 255

ExecStart=/home/minecraft/service_check.sh

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/service_check.service

# Setting perms on service_check.service
sudo chmod 644 /etc/systemd/system/service_check.service

sudo echo '#!/bin/bash

set -e

cd /home/minecraft
touch .online_users
touch .start_minecraft

sudo chown -R minecraft:minecraft .

while true; do
    logger "Player check loop has begun, or started anew!"

    logger "Calculating current number of online users via lsof on port 25565, sleeping for 5 seconds"
    lsof -iTCP:25565 -sTCP:ESTABLISHED > .online_users &
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
            lsof -iTCP:25565 -sTCP:ESTABLISHED > .online_users &
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
killall java
sleep 30

if pgrep -x java >/dev/null
then
    logger "There was an issue while killing the java service"
else
    logger "Minecraft server stopped successfully"
fi

logger "Shutting down Server in 1 minute..."
sudo shutdown' > /home/minecraft/player_check.sh

sudo echo '#!/bin/bash
set -e

cd /home/minecraft

bash -c "./service-check -svc minecraft.service -p 7777"
' > /home/minecraft/service_check.sh


# Enable all services so that they run on reboot
sudo systemctl enable minecraft
sudo systemctl enable player_check
sudo systemctl enable service_check

# Makes shell scripts executable in mc-server/
chmod a+x /home/minecraft/*.sh

# Start the services
sudo systemctl start minecraft
sudo systemctl start player_check
sudo systemctl start service_check
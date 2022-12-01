# mc-server
A place for me to keep my scripts relating to my Minecraft server

## General Description
About once a year or so, my friends and I get an itch to play some Minecraft together. This repository serves as a script dump for the server.

## What's in here?

`service-check`: An executable built from my [`service-check` Github Project](https://github.com/jacob-howe/service-check). It is used to broadcast whether or not Minecraft is running over port 7777. You can configure what port this service check runs on by changing line 184 in `userdata.sh`

`eula.txt`: Accepts Mojang's [end user license agreement](https://account.mojang.com/documents/minecraft_eula).

`server.properties`: The properties I've set for my friends' and I's Minecraft server. Check out [this Minecraft Wiki on `server.properties`](https://minecraft.fandom.com/wiki/Server.properties) for more information on what each argument changes.

`README.md`: This :)

`userdata.sh`: IT DOES EVERYTHING. It creates the `minecraft` service, `player_check` service, assigns appropriate permissions, and more! It's pretty well commented, so check it out.

## How can I use this?

If you have an AWS account, you can follow the steps below to get this working for you:

1. Sign into the AWS console and navigate to EC2
1. Click `Launch Instances` in the top left corner of your screen
1. Configure your EC2 instance to your liking (make sure it's in a public subnet and has a public IP address or you'll be unable to access your Minecraft server!)
1. On `Step 3: Configure Instance`, once you're done configuring everything to your liking, at the bottom you'll see a field for `User data`. Select the `As file` radio button, and upload `userdata.sh`.
1. Configure the rest of your server to your liking with regards to storage, tags, and security groups.
1. Launch your server and enjoy! :)

Alternatively, if you have an AWS account and want the power to control your Minecraft server from the comfort of your very own Discord server, [checkout my `discord-ec2-manager` project](https://github.com/jacob-howe/discord-ec2-manager).

## What if I don't have an AWS account?
If you _don't_ have an AWS account, you can run the server locally via Docker & Docker Compose

1. Navigate to where you cloned this repository
1. Open `Docker Desktop` and ensure that the docker engine is running on your computer
1. Open Powershell and type `docker compose up -d`
1. Open Minecraft and your server should be up on port `25565`!

## Additional Links / Resources
* [Minecraft Wiki](https://minecraft.fandom.com/wiki/Minecraft_Wiki)
* [`server.properties` Breakdown via Minecraft Wiki](https://minecraft.fandom.com/wiki/Server.properties)
* [Mojang's End User License Agreement (EULA) for Minecraft](https://account.mojang.com/documents/minecraft_eula)
* [`discord-ec2-manager` Project by yours truly :)](https://github.com/jacob-howe/discord-ec2-manager)
* [`service-check` Project by yours truly :)](https://github.com/jacob-howe/service-check)
* [Amazon Web Services' (AWS) 'Getting Started with EC2' Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html)

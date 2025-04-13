import requests
import random

# This script is used to register the commands for the Discord bot. You must
# update the instances array to include your own GCP instances in order to use
# the bot in your own Discord server.

instance_choices = []

app_id = "<REPLACE_ME>"
dedidated_wam_id = "<REPLACE_ME>"

public_discord_key = "<REPLACE_ME>"
bot_token = "<REPLACE_ME>"

gcp_project = "<REPLACE_ME>"

def generate_2fa():
    return random.randint(10000000, 99999999)

def register_commands(command):
    url = f"https://discord.com/api/v10/applications/{app_id}/guilds/{dedidated_wam_id}/commands"

    headers = {
        "Authorization": f"Bot {bot_token}"
    }

    response = requests.post(url, headers=headers, json=command)
    if response.status_code == "200":
        print(f"LINE 22: {response.json}")
        return True
    else:
        print(f"LINE 25: {response.json}")
        return False

# This is only displayed once!
stop_code = generate_2fa()
print(f"Stop Code: {stop_code}")

# Because the AggregateList API method takes too long, we're going to hardcode options here
instances = [
    {
        "name": "Minecraft 2025 (Java)",
        "instance_value": "minecraft-2025",
        "project": gcp_project,
        "zone": "us-east5-c",
        "server_url": "2025.minecraft.card-howe.com:25565",
        "stop_code": stop_code
    }
    {
        "name": "Minecraft 2024 (Bedrock)",
        "instance_value": "minecraft-2024",
        "project": gcp_project,
        "zone": "us-east5-c",
        "server_url": "2024.minecraft.card-howe.com:19132",
        "stop_code": stop_code
    },
]

for instance in instances:
    print(instance)
    instance_choices.append(
        {
            "name": instance["name"],
            "value": instance["instance_value"]
        }
    )

commands = [
    {
        "name": "start",
        "type": 1,
        "description": "Start a game server",
        "options": [
            {
                "name": "server",
                "description": "The game server you want to start",
                "type": 3,
                "required": True,
                "choices": instance_choices
            }
        ]
    },
    {
        "name": "stop",
        "type": 1,
        "description": "Stop a game server",
        "options": [
            {
                "name": "server",
                "description": "The game server you want to stop",
                "type": 3,
                "required": True,
                "choices": instance_choices
            },
            {
                "name": "2fa",
                "description": "The code require to stop the server",
                "type": 4,
                "required": True,
            }
        ]
    },
    {
        "name": "status",
        "type": 1,
        "description": "Status of a game server",
        "options": [
            {
                "name": "server",
                "description": "The game server you want to get the status of",
                "type": 3,
                "required": True,
                "choices": instance_choices
            }
        ]
    }
]

# print("LINE 117: Registering commands...")
def main():
    for command in commands:
        register_commands(command=command)

if __name__ == "__main__":
    main()

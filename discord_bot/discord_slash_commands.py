# This python script was written, and tested in Google Cloud Functions running
# on a Pyhon 3.12 Base Image (Ubuntu 22.04 Full). It has not been tested for
# any other Cloud Provider, though I suspect porting it to AWS or Azure wouldn't
# be too large of a lift.

# Some important notes about the Cloud Run Function's configuration within GCP:
# 1. You need to allow ALL ingress traffic, and unauthenticated requests
# 2. The container this runs on is open at port 8080
# 3. The container has 256MiB of memory and <1 vCPU
# 4. Request timeout is 60s

# Make sure to replace any default '<REPLACE_ME>' values with your own configs

# @TODO: Add this to the README
import functions_framework
import requests
import time
import sys
import random
import os
from typing import Any

from google.api_core.extended_operation import ExtendedOperation
from google.cloud import compute_v1

from flask import abort
from flask import jsonify
from nacl.exceptions import BadSignatureError
from nacl.signing import VerifyKey

app_id = os.environ.get("DISCORD_APP_ID")
dedidated_wam_id = os.environ.get("DISCORD_SERVER_ID")

public_discord_key = os.environ.get("DISCORD_APP_PUBLIC_KEY")
bot_token = os.environ.get("DISCORD_BOT_TOKEN")

gcp_project = os.environ.get("GCP_PROJECT")

instance_choices = [] # Gets populated below

def get_instance_by_value(instance_value):
    for instance in instances:
        if instance.get('instance_value') == instance_value:
            return instance
    return None

def register_commands(command):
    url = f"https://discord.com/api/v10/applications/{app_id}/guilds/{dedidated_wam_id}/commands"

    headers = {
        "Authorization": f"Bot {bot_token}"
    }

    response = requests.post(url, headers=headers, json=command)
    if response.status_code == "200":
        return True

    return False

def default_reply(interaction_id, interaction_token):
    url = f"https://discord.com/api/v10/interactions/{interaction_id}/{interaction_token}/callback"
    reply = {
        "type": 4,
        "data": {
                "tts": False,
                "content": f"This is from Cloud Functions! {interaction_id}",
                "embeds": [],
                "allowed_mentions": {"parse": []},
        }
    }

    # print("LINE 75: Attempting to respond to interaction...") # Debug
    response = requests.post(url, json=reply)
    return f"{response.status_code}"

def start_server(interaction_id, interaction_token, server_name):
    default_callback_url = f"https://discord.com/api/v10/interactions/{interaction_id}/{interaction_token}/callback"

    found_instance = get_instance_by_value(server_name)

    if found_instance == None:
        reply = {
            "type": 4,
            "data": {
                "tts": False,
                "content": f"`{server_name}` not found. Did it get deleted? Did Jacob forget to add it to the options list?",
                "embeds": [],
                "allowed_mentions": {"parse":[]},
            }
        }
        response = requests.post(default_callback_url, json=reply)
        return f"{response.status_code}"


    client = compute_v1.InstancesClient()

    client.start(
        instance = found_instance["instance_value"],
        project = found_instance["project"],
        zone = found_instance["zone"]
    )

    reply = {
        "type": 4,
        "data": {
                "tts": False,
                "content": f"**Successfully started `{server_name}`!**\n\nThe game server should be up and running at `{found_instance["server_url"]}`!\n\n_You can also access it via the public IP address found via the `/status` command._",
                "embeds": [],
                "allowed_mentions": {"parse": []},
        }
    }

    response = requests.post(default_callback_url, json=reply)
    return f"{response.status_code}"

def stop_server(interaction_id, interaction_token, server_name, stop_code):
    default_callback_url = f"https://discord.com/api/v10/interactions/{interaction_id}/{interaction_token}/callback"

    found_instance = get_instance_by_value(server_name)

    if found_instance == None:
        reply = {
            "type": 4,
            "data": {
                "tts": False,
                "content": f"`{server_name}` not found.",
                "embeds": [],
                "allowed_mentions": {"parse":[]},
            }
        }
        response = requests.post(default_callback_url, json=reply)
        return f"{response.status_code}"

    if found_instance["stop_code"] != stop_code:
        reply = {
            "type": 4,
            "data": {
                "tts": False,
                "content": "Don't be a dick.",
                "embeds": [],
                "allowed_mentions": {"parse":[]},
            }
        }
        response = requests.post(default_callback_url, json=reply)
        return f"{response.status_code}"

    client = compute_v1.InstancesClient()

    client.stop(
        instance = found_instance["instance_value"],
        project = found_instance["project"],
        zone = found_instance["zone"]
    )

    reply = {
        "type": 4,
        "data": {
                "tts": False,
                "content": f"**Stopping `{server_name}`!**",
                "embeds": [],
                "allowed_mentions": {"parse": []},
        }
    }

    response = requests.post(default_callback_url, json=reply)
    return f"{response.status_code}"

def status_server(interaction_id, interaction_token, server_name):
    default_callback_url = f"https://discord.com/api/v10/interactions/{interaction_id}/{interaction_token}/callback"

    found_instance = get_instance_by_value(server_name)

    if found_instance == None:
        reply = {
            "type": 4,
            "data": {
                "tts": False,
                "content": f"`{server_name}` not found.",
                "embeds": [],
                "allowed_mentions": {"parse":[]},
            }
        }
        response = requests.post(default_callback_url, json=reply)
        return f"{response.status_code}"

    client = compute_v1.InstancesClient()

    instance_info = client.get(
        instance = found_instance["instance_value"],
        project = found_instance["project"],
        zone = found_instance["zone"]
    )

    network_interface = instance_info.network_interfaces[0]
    access_config = network_interface.access_configs[0]
    public_ip = access_config.nat_i_p

    game_server_status = ""

    # Check if an access config is available
    if network_interface.access_configs:
        # # Assume the first access config has the external IP
        # access_config = network_interface.access_configs[0]
        # public_ip = access_config.nat_i_p

        try:
            game_server_response = requests.get(f"http://{public_ip}:7777", timeout=0.25)
        except:
            game_server_status = "The request timed out. Is the host online?"
            reply = {
                "type": 4,
                "data": {
                        "tts": False,
                        "content": f"**Server info:**\n* Host Status: `{instance_info.status}`\n* Game Server Status: `{game_server_status}`\n* Public IP: `{public_ip}`",
                        "embeds": [],
                        "allowed_mentions": {"parse": []},
                }
            }
            response = requests.post(default_callback_url, json=reply)
            return f"{response.status_code}"
        print(game_server_response)
        # print(game_server_response) # Debug
        # print(game_server_response.status_code) # Debug
        if game_server_response.status_code == 200:
            game_server_status = "Minecraft is running!"
        else:
            game_server_status = "Either Minecraft is not running, or the host server is down. Couldn't get game server status, try again later!"
    else:
        game_server_status = "The host is offline. Minecraft is not running."

    reply = {
        "type": 4,
        "data": {
                "tts": False,
                "content": f"**Server info:**\n* Host Status: `{instance_info.status}`\n* Game Server Status: `{game_server_status}`\n* Public IP: `{public_ip}`",
                "embeds": [],
                "allowed_mentions": {"parse": []},
        }
    }
    response = requests.post(default_callback_url, json=reply)
    return f"{response.status_code}"

def validate_request(request):
    verify_key = VerifyKey(bytes.fromhex(public_discord_key))
    signature = request.headers["X-Signature-Ed25519"]
    timestamp = request.headers["X-Signature-Timestamp"]
    body = request.data.decode("utf-8")

    try:
        verify_key.verify(f"{timestamp}{body}".encode(), bytes.fromhex(signature))
    except BadSignatureError:
        return False
    return True

def generate_2fa():
    return random.randint(10000000, 99999999)

@functions_framework.http
def handle_request(request):
    # print(request.headers) # Debug
    # Checks that the request is valid
    is_valid = validate_request(request)
    if not is_valid:
        abort(401, "invalid request signature")

    # print("LINE 105: Checking request type...") # Useful debugging line
    # Checks request type
    request_type = request.json["type"]
    # Discord Ping
    if request_type == 1:
        return jsonify({"type": 1}) # Required to validate that Discord can access the bot's endpoint URL (Cloud Function)
    else:
        interaction_id  = request.json["id"]
        interaction_token = request.json["token"]
        command_name = request.json["data"]["name"]
        server_name = request.json["data"]["options"][0]["value"]

        # print(request.json) # Debug

        if command_name == 'start':
            return start_server(interaction_id, interaction_token, server_name)

        if command_name == 'stop':
            stop_code = request.json["data"]["options"][1]["value"]
            return stop_server(interaction_id, interaction_token, server_name, stop_code)

        if command_name == 'status':
            return status_server(interaction_id, interaction_token, server_name)

        return default_reply(interaction_id, interaction_token)

# This is only displayed once!
stop_code = generate_2fa()
print(f"Stop Code: {stop_code}")

# Because the AggregateList API method takes too long, we're going to hardcode options here
instances = [
    {
        "name": "Minecraft 2024 (Bedrock)",
        "instance_value": "minecraft-2024",
        "project": "jch-minecraft",
        "zone": "us-east5-c",
        "server_url": "minecraft.card-howe.com:19132",
        "stop_code": stop_code
    },
    {
        "name": "Minecraft 2025 (Java)",
        "instance_value": "minecraft-2025",
        "project": "jch-minecraft",
        "zone": "us-east5-c",
        "server_url": "minecraft.card-howe.com:25565",
        "stop_code": stop_code
    },
]

for instance in instances:
    # print(instance) # Debug
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
for command in commands:
    register_commands(command=command)

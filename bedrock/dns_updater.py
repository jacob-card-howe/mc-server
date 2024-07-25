# Inspired by mini-hard-cowe/services/update-dns/update_dns.py


import json
import logging
import os
import requests
import sys

# Configure logging
logformat = "%(asctime)s %(levelname)s %(module)s: %(message)s"
dateformat = "%m-%d %H:%M"

logging.basicConfig(
    filename="./update_dns.log",
    level = logging.INFO,
    filemode="w",
    format = logformat,
    datefmt = dateformat,
)

stream_handler = logging.StreamHandler(sys.stderr)
stream_handler.setFormatter(logging.Formatter(fmt=logformat, datefmt=dateformat))

logger = logging.getLogger("update_dns")
logger.addHandler(stream_handler)

# Set the required variables
api_key = os.getenv("CLOUDFLARE_GLOBAL_API_TOKEN")
email = os.getenv("CLOUDFLARE_EMAIL")

ip_check = requests.get("https://api.ipify.org").text

logger.info(f"Current IP: {ip_check}")
logger.info(f"API Key: {api_key}")
logger.info(f"Email: {email}")

# Attempt to load DNS records from dns_records.json
try:
    with open("dns_records.json") as f:
        logger.info("Loading dns_records.json file...")
        params_array = json.load(f)
except FileNotFoundError:
    logger.error("dns_records.json not found, exiting...")
    exit(1)

logger.info("Starting update_dns.py script...")
for params in params_array["records"]:

    zone_id = params["zone_id"]
    record_name = params["record_name"]
    record_id = params["record_id"]
    current_ip = params["ip_addr"]

    # Set the headers
    headers={
        "X-Auth-Key": api_key,
        "X-Auth-Email": email,
        "Content-Type": "application/json"
    }

    if not params["record_id"]:
        logger.info(f"Record ID not found for {record_name} in dns_records.json, attempting to fetch it from Cloudflare...")

        url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type=A&name={record_name}"

        response = requests.get(
            url,
            headers=headers
        )

        if response.status_code != 200:
            logger.error(f"Error getting record ID for {record_name}: {response.status_code} {response.json()}")
            continue

        try:
            record_id = response.json()["result"][0]["id"]
            params["record_id"] = record_id

            # Write the updated record to file
            with open("dns_records.json", "w") as f:
                json.dump(params_array, f, indent=4)
        except (IndexError, KeyError):
            logging.error(f"Error getting record ID for {record_name}: {response.json()}")
            continue

    if not params["ip_addr"]:
        logger.info(f"IP address not currently set in dns_records.json for {params['record_name']}, setting it to {ip_check}...")
        params["ip_addr"] = ip_check
        with open("dns_records.json", "w") as f:
            json.dump(params_array, f, indent=4)

    if params["ip_addr"] == ip_check:
        logger.info(f"IP address for {params['record_name']} is already set to {ip_check}, skipping...")
        continue
    else:
        logger.info(f"IP address for {params['record_name']} does not match {ip_check}, updating...")
        params["ip_addr"] = ip_check
        current_ip = ip_check
        with open("dns_records.json", "w") as f:
            json.dump(params_array, f, indent=4)


    logger.info(f"Beginning update for {record_name}")

    # Update the record in Cloudflare
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"

    if record_name == "minecraft.card-howe.com":
        proxy_val = False
    else:
        proxy_val = True

    data = {"type": "A", "name": record_name, "content": current_ip, "ttl": 120, "proxied": proxy_val}

    response = requests.put(
        url,
        headers=headers,
        data=json.dumps(data)).json()

    if response["success"]:
        logger.info(f"Record updated with IP address: {current_ip}\n\n")
        params["ip_addr"] = current_ip

        with open("dns_records.json", "w") as f:
            json.dump(params_array, f, indent=4)
    else:
        logger.error(f"Record update failed: {response['errors']}\n\n")

if not params_array:
    logger.error("No records found in dns_records.json, please create a valid JSON document in the following format:\n\n\{\n\t\"zone_id\": \"<zone_id>\",\n\t\"record_name\": \"<record_name>\",\n\t\"record_id\": \"<record_id>\",\n\t\"ip_addr\": \"<ip_addr>\"\n\}\n\n")
    exit(1)

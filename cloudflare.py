#!/usr/bin/env python3
import argparse
import json
import os
import time
import warnings

import requests
from dotenv import load_dotenv

# Suppress the specific warning from urllib3
warnings.filterwarnings("ignore", message=".*NotOpenSSLWarning.*")

KEY_CFTOKEN = "CLOUDFLARE_TOKEN"
KEY_CFZONE = "CLOUDFLARE_ZONE"
KEY_CFRECORD = "CLOUDFLARE_RECORD"
KEY_CFVALUE = "CERTBOT_VALIDATION"


def update_cloudflare_dns_txt_record(token=None, zone=None, 
                                     record=None, value=None):
    assert token is not None, "Cloudflare API token must be provided"
    assert zone is not None, "Cloudflare zone id must be provided"
    assert record is not None, "DNS record name must be provided"
    assert value is not None, "DNS record value must be provided"

    # Cloudflare API URL
    API_URL = f"https://api.cloudflare.com/client/v4/zones/{zone}/dns_records"

    # Headers for authentication
    HEADERS = {"Authorization": f"Bearer {token}",
               "Content-Type": "application/json"}

    # Get the TXT record ID
    response = requests.get(
        API_URL, headers=HEADERS, params={"type": "TXT", "name": record}
    )
    data = response.json()

    if not data["success"] or not data["result"]:
        print("Failed to retrieve DNS record.")
        exit(1)

    record_id = data["result"][0]["id"]

    # Update the TXT record
    update_url = f"{API_URL}/{record_id}"
    payload = {
        "type": "TXT",
        "name": record,
        "content": f'"{value}"',
        "ttl": 120,  # Time-to-live in seconds
    }

    update_response = requests.put(
        update_url, headers=HEADERS, data=json.dumps(payload)
    )
    update_data = update_response.json()

    if update_data["success"]:
        return (True, "TXT record updated successfully.")
    else:
        return (False, f"Failed to update TXT record:{update_data}")


def main():
    # for key, value in os.environ.items():
    #     if key.startswith("CERTBOT") or key.startswith("CLOUDFLARE"):
    #         print(f"{key}: {value}")
    # Load environment variables from .env file
    load_dotenv()
    parser = argparse.ArgumentParser(
        description="Certbot Authorization Hook for Cloudflare."
    )
    parser.add_argument(
        "--token",
        default=os.environ.get(KEY_CFTOKEN, None),
        help="Cloudflare API token (if not provided, read from environment " +
             f"variable {KEY_CFTOKEN})",
    )
    parser.add_argument(
        "--zone",
        default=os.environ.get(KEY_CFZONE, None),
        help="Cloudflare zone id (if not provided, read from environment " +
             f"variable {KEY_CFZONE})",
    )
    parser.add_argument(
        "--record",
        default=os.environ.get(KEY_CFRECORD, None),
        help="DNS record name (if not provided, read from environment " +
        f"variable {KEY_CFRECORD})",
    )
    parser.add_argument(
        "--value",
        default=os.environ.get(KEY_CFVALUE, None),
        help="DNS record value (if not provided, read from environment " +
        f"variable {KEY_CFVALUE})",
    )
    args = parser.parse_args()

    try:
        response = update_cloudflare_dns_txt_record(
                                                    token=args.token,
                                                    zone=args.zone,
                                                    record=args.record,
                                                    value=args.value)
        if response[0]:
            time.sleep(30)
        else:
            print(response[1])
    except Exception as e:
        print(e)


if "__main__" == __name__:
    main()

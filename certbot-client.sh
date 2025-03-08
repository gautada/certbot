#!/bin/sh
# This script wraps the acme certbot into a simple script

TARGET_USER="coyote"
# Check if script is running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Running as root, switching to $TARGET_USER..."
    exec sudo --preserve-env --user "$TARGET_USER" -- "$0" "$@"
fi
echo "Running as $USER"

if [ -z "$CERTBOT_EMAIL" ]; then
    echo "Error: CERTBOT_EMAIL is not set or empty" >&2
    exit 1
fi

if [ -z "$CERTBOT_DOMAIN" ]; then
    echo "Error: CERTBOT_DOMAIN is not set or empty" >&2
    exit 1
fi

VAULT="/home/coyote/vault"
if [ -n "$CERTBOT_VAULT" ]; then
    VAULT="$CERTBOT_VAULT"
fi

MODE="TEST"
# Check if "--production" is provided as a CLI argument
if [ "${1}" = "--production" ]; then
    MODE="PRODUCTION"
fi

VERB=$(basename "$0")

CONFIG_DIR="${VAULT}/config"
LOG_DIR="${VAULT}/logs"
WORK_DIR="${VAULT}/work"

echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# shellcheck disable=SC1091
. "/home/coyote/.venv/bin/activate"
if [ "${MODE}" = "PRODUCTION" ]; then
    echo "1"
    exec "/home/coyote/.venv/bin/certbot" "${VERB}" -v \
    --agree-tos \
    --manual \
    --noninteractive \
    --config-dir="${CONFIG_DIR}" \
    --logs-dir="${LOG_DIR}" \
    --work-dir="${WORK_DIR}" \
    --email="${CERTBOT_EMAIL}" \
    --manual-auth-hook="/home/coyote/.venv/bin/cloudflare" \
    --preferred-challenges=dns \
    -d "*.${CERTBOT_DOMAIN}"
    echo "2"
else
    echo "3"
    exec "/home/coyote/.venv/bin/certbot" "${VERB}" -v \
    --agree-tos \
    --dry-run \
    --manual \
    --noninteractive \
    --test-cert \
    --config-dir="${CONFIG_DIR}" \
    --logs-dir="${LOG_DIR}" \
    --work-dir="${WORK_DIR}" \
    --email="${CERTBOT_EMAIL}" \
    --manual-auth-hook="/home/coyote/.venv/bin/cloudflare" \
    --preferred-challenges=dns \
    -d "*.${CERTBOT_DOMAIN}" && /home/coyote/.venv/bin/update-cluster
    echo "4"
fi
deactivate

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
/home/coyote/.venv/bin/update-cluster
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"


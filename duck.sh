#!/usr/bin/env bash

# Directory to store logs
DUCKPATH=~/duckdns
mkdir -p "$DUCKPATH"  # Create the directory if it does not exist

# Load configuration from an external file (avoids exposing the token in the script)
CONFIG_FILE="$DUCKPATH/config.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file $CONFIG_FILE not found." | tee -a "$DUCKPATH/stderr.log"
    exit 1
fi

# Check if essential variables are defined
if [[ -z "$TOKEN" || -z "$DOMAINS" ]]; then
    echo "Error: TOKEN or DOMAINS not properly set in $CONFIG_FILE." | tee -a "$DUCKPATH/stderr.log"
    exit 1
fi

# Get the current public IP
CURRENT_IP=$(curl -s https://api64.ipify.org)

# Check if we have a previously saved IP
IP_FILE="$DUCKPATH/last_ip.txt"
if [ -f "$IP_FILE" ]; then
    LAST_IP=$(cat "$IP_FILE")
else
    LAST_IP=""
fi

# Check if it's the first update of the day
FORCE_UPDATE_FILE="$DUCKPATH/last_force_update.txt"
TODAY=$(date +%Y-%m-%d)
if [ -f "$FORCE_UPDATE_FILE" ]; then
    LAST_FORCE_UPDATE=$(cat "$FORCE_UPDATE_FILE")
else
    LAST_FORCE_UPDATE=""
fi

FORCE_UPDATE=false
if [ "$TODAY" != "$LAST_FORCE_UPDATE" ]; then
    FORCE_UPDATE=true
    echo "$TODAY" > "$FORCE_UPDATE_FILE"  # Save the last force update date
fi

# Update only if the IP has changed or it's the first update of the day
if [ "$CURRENT_IP" != "$LAST_IP" ] || [ "$FORCE_UPDATE" = true ]; then
    RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=${CURRENT_IP}")
    
    # Verify if the response is "OK"
    if [[ "$RESPONSE" == "OK" ]]; then
        echo "$CURRENT_IP" > "$IP_FILE"  # Save the new IP
        echo "$(date '+%Y-%m-%d; %H:%M:%S; UTC'); IP updated: $CURRENT_IP" | tee -a "$DUCKPATH/stdout.log"
    else
        echo "$(date '+%Y-%m-%d; %H:%M:%S; UTC'); Error updating IP: $RESPONSE" | tee -a "$DUCKPATH/stderr.log"
    fi
fi

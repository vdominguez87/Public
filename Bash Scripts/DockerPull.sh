#!/bin/bash

# Path to Compose file
DOCKER_COMPOSE_FILE="/Docker/docker-compose.yaml"

# Stop Docker Compose services
docker compose -f "$DOCKER_COMPOSE_FILE" down

# Pull latest images
PULL_OUTPUT=$(docker-compose -f "$DOCKER_COMPOSE_FILE" pull 2>&1)

# Initialize an array to store new images
NEW_IMAGES=()

# Check if any new images were pulled
while IFS= read -r line; do
    if [[ $line == *"Downloaded newer image"* ]]; then
        # Extract the name of the new image pulled
        NEW_IMAGE=$(echo "$line" | awk '{print $NF}')
        NEW_IMAGES+=("$NEW_IMAGE")
    fi
done <<< "$PULL_OUTPUT"

# Prune older images/volumes if new images were pulled
if [[ ${#NEW_IMAGES[@]} -gt 0 ]]; then
    docker image prune -af & docker volume prune -af
fi

# Start Docker Compose services and capture the output
START_OUTPUT=$(docker compose -f "$DOCKER_COMPOSE_FILE" up -d 2>&1)

# Check if Docker containers started successfully or failed
if [[ $START_OUTPUT == *"Starting"*"Started"* ]]; then
    START_STATUS="Compose Status: Success"
else
    START_STATUS="Compose Status: Failure"
fi

# Get current date range for the following 7 days
DATE_RANGE=$(date +"%Y-%m-%d" -d "today - 7 days")" to "$(date +"%Y-%m-%d" -d "today")

# Prepare email subject and body based on new images
if [[ ${#NEW_IMAGES[@]} -gt 0 ]]; then
    # Send email with details of the new images and start status
    SUBJECT="Maintenance Complete: New Image(s) Available ($DATE_RANGE)"
    BODY="New Docker images have been pulled and installed:\n"
    for image in "${NEW_IMAGES[@]}"; do
        BODY+="  - $image\n"
    done
    BODY+="\nDate Range: $DATE_RANGE\n\n$START_STATUS"
else
    # No new images pulled, send email with start status only
    SUBJECT="Maintenance Complete: No Image Updates Available ($DATE_RANGE)"
    BODY="All Docker images are up-to-date. No changes have been made.\n\n$START_STATUS"
fi

# Send email using sendmail
echo -e "$BODY" | mail -s "$SUBJECT" -aFrom:Docker\<sender@gmail.com\> recipient@gmail.com
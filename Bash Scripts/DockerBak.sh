#!/bin/bash

# Get current month and year
CURRENT_MONTH=$(date +"%B")
CURRENT_YEAR=$(date +"%Y")

# Other Variables
NFS_SERVER="192.168.x.x"
NFS_PATH="/Backups/Docker"
LOCAL_MOUNT="/Backups"
SOURCE_DIR="/home/docker_ct/.local/share/docker/volumes"
DATE_RANGE="$CURRENT_MONTH, $CURRENT_YEAR"
SUBJECT="Backup Complete: Docker Volumes - ($DATE_RANGE)"
BODY="The scheduled backup operation 'Docker Volumes - ($DATE_RANGE)' has completed successfully."

# Create mount point if it doesn't exist
if [ ! -d "$LOCAL_MOUNT" ]; then
  mkdir -p "$LOCAL_MOUNT"
fi

# Mount NFS share
mount "$NFS_SERVER:$NFS_PATH" "$LOCAL_MOUNT"

# Check if mount was successful
if [ $? -ne 0 ]; then
  echo "The NFS mount operation for /Backups has failed. Please check the logs." | mail -s "Mount Failure: /Backups - ($DATE_RANGE)" -aFrom:Rsync\<sender@gmail.com\> recipient@gmail.com
  exit 1
fi

# Perform rsync operation
rsync -av --delete --update --perms --times --group --owner "$SOURCE_DIR" "$LOCAL_MOUNT"

# Check if rsync was successful
if [ $? -ne 0 ]; then
  echo "The scheduled backup operation 'Docker Volumes - ($DATE_RANGE)' has failed. Please check the logs." | mail -s "Backup Failure: Docker Volumes - ($DATE_RANGE)" -aFrom:Rsync\<sender@gmail.com\> recipient@gmail.com
  umount "$LOCAL_MOUNT"
  exit 1
fi

# Unmount NFS
umount "$LOCAL_MOUNT"

# Check if unmount was successful
if [ $? -ne 0 ]; then
  echo "The NFS unmount operation for /Backups has failed. Please check the logs." | mail -s "Unmount Failure: /Backups - ($DATE_RANGE)" -aFrom:Rsync\<sender@gmail.com\> recipient@gmail.com
  exit 1
fi

# Remove mount point
rm -rf "$LOCAL_MOUNT"

#Send success email
echo "$BODY" | mail -s "$SUBJECT" -aFrom:Rsync\<sender@gmail.com\> recipient@gmail.com
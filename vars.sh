#!/bin/bash

# CRON time to run session-start
STARTCRON="35 13 * * *" # 7 PM TUESDAY
# CRON time to run session-end 
STOPCRON="45 13 * * *"  # 9 PM TUESDAY
# CRON time to send notification to players
NOTIFY_TIME="45 18 * * 2"      # 6:45 TUESDAY
NOTIFY_MESSAGE="Server coming online in 15 minutes!"
# CONSTANTS
S3BUCKET="weekly-minecraft"
# LOCATION of various things on disk
APPDIR=/opt/mc
LOGDIR=/var/log/mc
LOGFILE=$LOGDIR/opt.log
BACKUP_NAME="worlddata.zip"
# Whether to start on a timer or just at boot
# If autostart is true, server will run indefinitely.
# Else server will run on cron timer
AUTOSTART="false"
# Name for server session
SERVER_SESSION_NAME="mc"
# APT dependencies
DEPENDENCIES="openjdk-8-jre curl unzip awscli tmux cron zip"
# Route53 hosted zone
ROUTE53_ZONE="Z1W5O98VODO3T3"
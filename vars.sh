#!/bin/bash

# CRON time to run session-start
SERVER_STARTTIME="00 19 * * 2" # 7 PM TUESDAY
# CRON time to run session-end 
SERVER_STOPTIME="00 21 * * 2"  # 9 PM TUESDAY
# CRON time to send notification to players
NOTIFY_TIME="45 18 * * 2"      # 6:45 TUESDAY
NOTIFY_MESSAGE="Server coming online in 15 minutes!"
# CONSTANTS
S3BUCKET="weekly-minecraft"
# LOCATION of various things on disk
APPDIR=/opt/mc
LOGDIR=/var/log/mc
LOGFILE=$LOGDIR/opt.log
# Whether to start on a timer or just at boot
# If autostart is true, server will run indefinitely.
# Else server will run on cron timer
AUTOSTART="true"
# Name for server session
SERVER_SESSION_NAME="mc"
# APT dependencies
DEPENDENCIES="curl unzip awscli tmux"
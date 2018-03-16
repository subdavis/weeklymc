#!/bin/bash

# Load variables
source $SCRIPTDIR/vars.sh

apt install -y $DEPENDENCIES

cd $APPDIR

# Create user accounts if they don't exist.
id -u mc || adduser --disabled-password --gecos "" mc
su mc

# Set DNS for the new public IP.
MYIP=$(curl https://api.ipify.org/)
# TODO: update r53 domain

# Get data from s3
aws s3 cp s3://$S3BUCKET/worlds/worlddata.zip worlddata.zip
if [ $? -eq 0 ]; then
	unzip worlddata.zip
	mv -v worlddata/* $APPDIR/
fi

# Get server jar from S3
aws s3 cp s3://$S3BUCKET/jars/spigot.jar $APPDIR/spigot.jar

# IF we should start the server immediately on boot
if [ "$AUTOSTART" = true ]; do
	$SCRIPTDIR/session.sh begin
else
	# Schedule CRON startup and shutdown.
	crontab -l > currentcron
	#echo new cron into cron file
	echo "$STARTCRON   $SCRIPTDIR/session.sh begin" >> newcron
	echo "$STOPCRON    $SCRIPTDIR/session.sh end"   >> newcron
	echo "$NOTIFY_TIME $SCRIPTDIR/session.sh notify players \"$NOTIFY_MESSAGE\"" >> newcron
	#install new cron file
	crontab newcron
	rm newcron
fi
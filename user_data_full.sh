#!/bin/bash -x

# Load variables
source /etc/environment
source $SCRIPTDIR/vars.sh

cd $SCRIPTDIR
git pull  # Runs at every reboot, so there could have been changes.

# These directories are needed later.
mkdir -p $APPDIR
mkdir -p $LOGDIR

apt install -y $DEPENDENCIES

cd $APPDIR

# Set DNS for the new public IP.
MYIP=$(curl https://api.ipify.org/)

# TODO: update r53 domain

# Get data from s3
aws s3 cp s3://$S3BUCKET/worlds/worlddata.zip worlddata.zip
if [ $? -eq 0 ]; then
	unzip worlddata.zip
else
	mkdir -p worlddata
fi

# Get server jar from S3
aws s3 cp s3://$S3BUCKET/jars/spigot.jar $APPDIR/spigot.jar

# Schedule CRON startup and shutdown.
crontab -l > currentcron

# IF we should start the server immediately on boot
if [ "$AUTOSTART" == "true" ]; then
	$SCRIPTDIR/session.sh begin
	sleep 86400 # In case we need to keep docker alive
else
	#echo new cron into cron file
	echo "$STARTCRON   $SCRIPTDIR/session.sh begin" >> newcron
	echo "$STOPCRON    $SCRIPTDIR/session.sh end"   >> newcron
	echo "$NOTIFY_TIME $SCRIPTDIR/session.sh notify players \"$NOTIFY_MESSAGE\"" >> newcron
fi

# Always run this script at reboot.
echo "@reboot      $SCRIPTDIR/user_data_full.sh" >> newcron
#install new cron file
crontab newcron
rm newcron
#!/bin/bash -x
# THIS SCRIPT RUNS EVERY BOOT

# Load variables
source /etc/environment
source $SCRIPTDIR/vars.sh

if [ -d $SCRIPTDIR ]; then
	cd $SCRIPTDIR
	git pull  # Runs at every reboot, so there could have been changes.
else
	mkdir -p $SCRIPTDIR
	cd $SCRIPTDIR/..
	git clone https://github.com/subdavis/weeklymc $SCRIPTDIR
fi

# These directories are needed later.
mkdir -p $APPDIR
mkdir -p $LOGDIR

apt install -y $DEPENDENCIES

cd $APPDIR

# Set DNS for the new public IP.
MYIP=$(curl https://api.ipify.org/)

# TODO: update r53 domain

# Get data from s3 IF NOT EXISTS
if [ ! -d $APPDIR/worlddata ]; then
	aws s3 cp "s3://$S3BUCKET/data/$BACKUP_NAME" "$APPDIR/$BACKUP_NAME" && unzip $BACKUP_NAME
fi

# Get server jar from S3
aws s3 cp s3://$S3BUCKET/jars/spigot.jar $APPDIR/spigot.jar

# Schedule CRON startup and shutdown.
crontab -l > currentcron

# IF we should start the server immediately on boot
if [ "$AUTOSTART" == "true" ]; then
	$SCRIPTDIR/session.sh begin
else
	#echo new cron into cron file
	echo "$STARTCRON   $SCRIPTDIR/session.sh begin >> $LOGDIR/begin.log" >> newcron
	echo "$STOPCRON    $SCRIPTDIR/session.sh end   >> $LOGDIR/end.log"   >> newcron
	echo "$NOTIFY_TIME $SCRIPTDIR/session.sh notify players \"$NOTIFY_MESSAGE\" >> $LOGDIR/notify.log" >> newcron
fi

# Always run this script at reboot.
echo "@reboot      $SCRIPTDIR/user_data_full.sh >> $LOGDIR/boot.log" >> newcron
#install new cron file
crontab newcron
rm newcron currentcron
sleep 86400 # In case we need to keep docker alive
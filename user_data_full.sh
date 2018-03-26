#!/bin/bash
# THIS SCRIPT RUNS EVERY BOOT

# Set a timestamp in the logs.
echo "RUN ON $(date)"

# Load variables
source /etc/environment
# Source again in case they changed in git.
source $SCRIPTDIR/vars.sh

# These directories are needed later.
mkdir -p $APPDIR/worlddata
mkdir -p $LOGDIR

apt install -y $DEPENDENCIES

# Set the timezone
timedatectl set-timezone America/New_York
# let cron realize these changes.
/etc/init.d/cron reload

cd $APPDIR

# Set DNS for the new public IP.
MYIP=$(curl https://api.ipify.org/)

# Update r53 domain
cat <<EOF > $APPDIR/updateR53.json 
{
  "Comment": "Update Route53 to point to new private IP",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "mc.aws.subdavis.com",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "$MYIP"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
	--hosted-zone-id $ROUTE53_ZONE \
	--change-batch file://$APPDIR/updateR53.json

# Get data from s3 IF NOT EXISTS
if [ ! -e $APPDIR/worlddata/eula.txt ]; then
	aws s3 cp "s3://$S3BUCKET/data/$BACKUP_NAME" "$BACKUP_NAME" && unzip $BACKUP_NAME
fi

# Move the new config files into place.
for f in $(ls $SCRIPTDIR/config); do
	cp $SCRIPTDIR/config/$f $APPDIR/worlddata/$f
done

# Get server jar from S3 if it doesn't exist.
aws s3 cp s3://$S3BUCKET/jars/spigot.jar $APPDIR/spigot.jar

# Get the plugins from S3
for p in $(echo "$ENABLED_PLUGINS"); do
	aws s3 cp s3://$S3BUCKET/plugins/$p $APPDIR/worlddata/plugins/$p
done

# Place the config folders for plugins....
for f in "$(ls $SCRIPTDIR/plugins)"; do
	mkdir -p "$APPDIR/worlddata/plugins/$f"
	for cfg in $(ls $SCRIPTDIR/plugins/$f); do
		rm "$APPDIR/worlddata/plugins/$f/$cfg"
		cp "$SCRIPTDIR/plugins/$f/$cfg" "$APPDIR/worlddata/plugins/$f/$cfg"
	done
done

# Schedule CRON startup and shutdown.
crontab -l > currentcron;

# IF we should start the server immediately on boot
if [ "$AUTOSTART" == "true" ]; then
	$SCRIPTDIR/session.sh begin
else
	#echo new cron into cron file
	echo "$STARTCRON   $SCRIPTDIR/session.sh begin                              >> $LOGDIR/begin.log 2>&1"  >> newcron
	echo "$STOPCRON    $SCRIPTDIR/session.sh end                                >> $LOGDIR/end.log 2>&1"    >> newcron
	echo "$NOTIFY_TIME $SCRIPTDIR/session.sh notify players \"$NOTIFY_MESSAGE\" >> $LOGDIR/notify.log 2>&1" >> newcron
fi

# Always run this script at reboot.
echo "@reboot $SCRIPTDIR/user_data_thin.sh >> $LOGDIR/boot.log 2>&1" >> newcron
#install new cron file
crontab newcron
rm newcron currentcron
sleep 86400 # In case we need to keep docker alive
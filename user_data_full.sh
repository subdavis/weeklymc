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
if [ ! -d $APPDIR/worlddata ]; then
	aws s3 cp "s3://$S3BUCKET/data/$BACKUP_NAME" "$BACKUP_NAME" && unzip $BACKUP_NAME
fi

# Move the new config files into place.
for f in $(ls $SCRIPTDIR/config); do
	rm $APPDIR/worlddata/$f
	cp $SCRIPTDIR/config/$f $APPDIR/worlddata/$f
done

# Get server jar from S3
aws s3 cp s3://$S3BUCKET/jars/spigot.jar $APPDIR/spigot.jar

# Schedule CRON startup and shutdown.
crontab -l > currentcron

# IF we should start the server immediately on boot
if [ "$AUTOSTART" == "true" ]; then
	$SCRIPTDIR/session.sh begin
else
	#echo new cron into cron file
	echo "$STARTCRON   $SCRIPTDIR/session.sh begin                              2>> $LOGDIR/begin.log"  >> newcron
	echo "$STOPCRON    $SCRIPTDIR/session.sh end                                2>> $LOGDIR/end.log"    >> newcron
	echo "$NOTIFY_TIME $SCRIPTDIR/session.sh notify players \"$NOTIFY_MESSAGE\" 2>> $LOGDIR/notify.log" >> newcron
fi

# Always run this script at reboot.
echo "@reboot      $SCRIPTDIR/user_data_full.sh 2>> $LOGDIR/boot.log" >> newcron
#install new cron file
crontab newcron
rm newcron currentcron
sleep 86400 # In case we need to keep docker alive
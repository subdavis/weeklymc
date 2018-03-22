#!/bin/bash -x

# LOAD CONFIG
source /etc/environment
source $SCRIPTDIR/vars.sh

alert () {
    GROUP=$1
    MESSAGE=$2

    echo "[$(date)] SENDING alert $MESSAGE to group $GROUP" >> $LOGFILE
}

session-begin () {
    # Start the server in a tmux session
    echo "[$(date)] BEGINNING session" >> $LOGFILE
    tmux new-session -d -s $SERVER_SESSION_NAME "$SCRIPTDIR/session.sh runserver"
}

session-end () {
    echo "[$(date)] ANNOUNCE end session" >> $LOGFILE
    tmux send-keys -t $SERVER_SESSION_NAME '/say Server going down in 15 seconds' Enter
    sleep 15

    echo "[$(date)] GRACEFULLY STOPPING tmux session" >> $LOGFILE
    # Gracefully stop the server
    tmux send-keys -t $SERVER_SESSION_NAME 'stop' Enter
    # Give the server 15 seconds to calm down.
    sleep 15
    # Kill session if we need to
    if [ "$(tmux ls 2>/dev/null | wc -l)" != "0" ]; then
        echo "[$(date)] UN-GRACEFULLY STOPPING tmux session" >> $LOGFILE
        tmux kill-session -t $SERVER_SESSION_NAME
        sleep 15
    fi
    # Backup
    pushd .
    server-backup && alert admins "Backup $BACKUP_NAME exported to s3."
    popd
}

server-backup () {
    # Backup to s3
    cd $APPDIR
    # Remove the plugin jars
    for p in "$ENABLED_PLUGINS"; do
        rm "$APPDIR/worlddata/plugins/$p"
    done
    # Backup world data to s3
    if [ -d $APPDIR/worlddata ]; then
        echo "[$(date)] BEGINNING data backup" >> $LOGFILE
        OLD_BACKUP_NAME="worlddata-$(date +%s).zip"
        BACKUP_NAME="worlddata.zip"
        # Remove the last backup if it exists.
        rm $BACKUP_NAME 
        zip -r $BACKUP_NAME worlddata/
        aws s3 mv "s3://$S3BUCKET/data/$BACKUP_NAME" "s3://$S3BUCKET/data/$OLD_BACKUP_NAME"
        aws s3 cp "$BACKUP_NAME" "s3://$S3BUCKET/data/$BACKUP_NAME"
    else
        echo "[$(date)] ERROR no world to back up" >> $LOGFILE
    fi
}

server-run () {
    # This script is for starting a server. 
    mkdir -p $APPDIR/worlddata && cd $APPDIR/worlddata

    echo "eula=true" > eula.txt
    echo "[$(date)] BEGINNING server restart loop" >> $LOGFILE
    while true; do
        java -jar -Xmx2G \
            -Xms2G -Xmn768m -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC \
            -XX:+UseParNewGC -XX:+UseNUMA -XX:+CMSParallelRemarkEnabled \
            -XX:MaxTenuringThreshold=15 -XX:MaxGCPauseMillis=30 \
            -XX:GCPauseIntervalMillis=150 -XX:+UseAdaptiveGCBoundary \
            -XX:-UseGCOverheadLimit -XX:+UseBiasedLocking -XX:SurvivorRatio=8 \
            -XX:TargetSurvivorRatio=90 -XX:MaxTenuringThreshold=15 -Dfml.ignorePatchDiscrepancies=true \
            -Dfml.ignoreInvalidMinecraftCertificates=true -XX:+UseFastAccessorMethods -XX:+UseCompressedOops \
            -XX:+OptimizeStringConcat -XX:+AggressiveOpts -XX:ReservedCodeCacheSize=2048m \
            -XX:+UseCodeCacheFlushing -XX:SoftRefLRUPolicyMSPerMB=10000 -XX:ParallelGCThreads=10 \
            $APPDIR/spigot.jar
        code=$?
        [ $code -eq 0 ] && break;
        echo "[$(date)] SERVER FAILED UN-GRACEFULLY with exit code $code" >> $LOGFILE
    done
    echo "[$(date)] ENDED server restart loop -- Goodbye" >> $LOGFILE
}

case $1 in
    alert)
        shift
        alert $@
        ;;
    begin)
        shift
        session-begin
        ;;
    end)
        shift
        session-end
        ;;
    runserver)
        shift
        server-run $@
        ;;
    *)
        echo "
./session.sh command [args]

Commands:
    alert \"message\"
    begin
    end
    runserver"
esac
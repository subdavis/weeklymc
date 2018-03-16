#!/bin/bash -x

# LOAD CONFIG
source $SCRIPTDIR/vars.sh

alert () {
    GROUP=$1
    MESSAGE=$2

    echo "[$(date)] SENDING alert $MESSAGE to group $GROUP" >> $LOGFILE
}

session-begin () {
    # Start the server in a tmux session
    echo "[$(date)] BEGINNING session" >> $LOGFILE
    tmux new -d -s $SERVER_SESSION_NAME $SCRIPTDIR/session.sh runserver
}

session-end () {
    echo "[$(date)] ENDING session" >> $LOGFILE
    echo "[$(date)] GRACEFULLY STOPPING tmux session" >> $LOGFILE
    # Gracefully stop the server
    tmux send-keys -t $SERVER_SESSION_NAME 'stop' Enter
    # Give the server 15 seconds to calm down.
    sleep 15
    # Send ctrl+c
    tmux send-keys -t $SERVER_SESSION_NAME C-c 
    # Give the server more time
    sleep 15

    # Backup to s3
    BACKUP_NAME="$(date +%s)-worlddata.zip"
    # Alert on backup
    alert admins "Backup $BACKUP_NAME exported to s3."
}

server-run () {
    # This script is for starting a server. 
    cd $APPDIR 
    echo "[$(date)] BEGINNING server restart loop" >> $LOGFILE
    while true; do
        java -jar -Xmx2G \
            -UseGCOverheadLimit \
            -Xms2G -Xmn768m -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC \
            -XX:+UseParNewGC -XX:+UseNUMA -XX:+CMSParallelRemarkEnabled \
            -XX:MaxTenuringThreshold=15 -XX:MaxGCPauseMillis=30 \
            -XX:GCPauseIntervalMillis=150 -XX:+UseAdaptiveGCBoundary \
            -XX:-UseGCOverheadLimit -XX:+UseBiasedLocking -XX:SurvivorRatio=8 \
            -XX:TargetSurvivorRatio=90 -XX:MaxTenuringThreshold=15 -Dfml.ignorePatchDiscrepancies=true \
            -Dfml.ignoreInvalidMinecraftCertificates=true -XX:+UseFastAccessorMethods -XX:+UseCompressedOops \
            -XX:+OptimizeStringConcat -XX:+AggressiveOpts -XX:ReservedCodeCacheSize=2048m \
            -XX:+UseCodeCacheFlushing -XX:SoftRefLRUPolicyMSPerMB=10000 -XX:ParallelGCThreads=10 \
            spigot.jar
        code=$?
        [ $code -eq 0 ] && break;
        echo "$(date) SERVER FAILED UN-GRACEFULLY with exit code $code" >> $LOGFILE
    done
    echo "$(date) ENDED server restart loop -- Goodbye" >> $LOGFILE
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
#!/bin/bash
set -euo pipefail

NEW_VPSNAME="$1"
TO_IP="$2"
TO_SSH_PORT="$3"
SPEED="$4"
VPS_NAME="$5"
SETMAXDOWNTIME="$6"
SHARED_ST_MIG="$7"
XML_FILE="$8"
LOGFILE="$9"

{
    echo "===== Live Migration Started ====="
    echo "$(date)"
    echo "NEW VPS NAME     $NEW_VPSNAME"
    echo "TO IP            $TO_IP"
    echo "TO SSH PORT      $TO_SSH_PORT"
    echo "SPEED            $SPEED"
    echo "VPS NAME         $VPS_NAME"
    echo "DOWNTIME         $SETMAXDOWNTIME"
    echo "SHARED STORAGE   $SHARED_ST_MIG"
    echo "XML_FILE         $XML_FILE"
} >> "$LOGFILE"

virsh migrate-setspeed "$VPS_NAME" --bandwidth "$SPEED"
virsh migrate-setmaxdowntime "$VPS_NAME" --downtime "$SETMAXDOWNTIME"

DEST_URI="qemu+ssh://root@${TO_IP}:${TO_SSH_PORT}/system?keyfile=/var/virtualizor/ssh-keys/id_rsa"

if [ "$SHARED_ST_MIG" = "1" ]; then
    MIGRATE_FLAGS="--live --verbose --dname ${NEW_VPSNAME} --xml ${XML_FILE}"
else
    MIGRATE_FLAGS="--live --verbose --copy-storage-all --dname ${NEW_VPSNAME} --xml ${XML_FILE}"
fi

virsh migrate $MIGRATE_FLAGS --desturi "$DEST_URI" "$VPS_NAME" >> "$LOGFILE" 2>&1
RET=$?

echo "Return code: $RET" >> "$LOGFILE"
echo "Migration completed" >> "$LOGFILE"
exit $RET

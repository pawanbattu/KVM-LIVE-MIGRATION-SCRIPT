#!/bin/bash
set -euo pipefail

DEST_IP="$1"
DEST_PORT="$2"
VPS_NAME="$3"

echo "Rolling back migration"
ssh -p "$DEST_PORT" root@"$DEST_IP" "virsh undefine $VPS_NAME --remove-all-storage || true"
echo "Rollback completed"

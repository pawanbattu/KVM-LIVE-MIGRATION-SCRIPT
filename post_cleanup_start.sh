#!/bin/bash
set -euo pipefail

DEST_IP="$1"
DEST_PORT="$2"
NEW_VM_NAME="$3"
OLD_VM_NAME="$4"

echo "Starting VM on destination..."
ssh -p "$DEST_PORT" root@"$DEST_IP" "virsh start '$NEW_VM_NAME' || true"

echo "Cleaning source VM definition..."
virsh undefine "$OLD_VM_NAME" --remove-all-storage || true

echo "Cleanup / auto-start completed."

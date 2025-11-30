#!/bin/bash
set -euo pipefail

VPS_NAME="$1"
DEST_IP="$2"
DEST_PORT="$3"

echo "=== Checking before migration ==="

# Verify VM status
state=$(virsh domstate "$VPS_NAME")
if [[ "$state" != "running" ]]; then
    echo "VM must be running — current state: $state"
    exit 1
fi
echo "VM is running"

# Check SSH connectivity
ssh -o BatchMode=yes -p "$DEST_PORT" root@"$DEST_IP" "echo connected" >/dev/null
echo "SSH passwordless OK"

# Check libvirt connectivity
virsh -c qemu+ssh://root@"$DEST_IP":$DEST_PORT/system list >/dev/null
echo "libvirt access OK"

# Check CPU compatibility
if ! virsh cpu-compare >/dev/null 2>&1; then
    echo "CPU mismatch — might cause slow migration, consider <cpu mode='host-model'/>"
else
    echo "CPU compatible"
fi

echo "=== All checks passed ==="

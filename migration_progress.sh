#!/bin/bash
set -euo pipefail

VM="$1"

while true; do
    status=$(virsh domjobinfo "$VM" 2>/dev/null)

    # Exit if migration finished
    if [[ $? -ne 0 ]]; then
        exit 0
    fi

    total=$(echo "$status" | awk '/Memory total:/ {print $3}')
    processed=$(echo "$status" | awk '/Memory processed:/ {print $3}')

    if [[ -n "$total" && "$total" -gt 0 ]]; then
        percent=$(( processed * 100 / total ))
        printf "\rMigration Progress: [%-50s] %3d%%" \
            $(printf "%0.s#" $(seq 1 $((percent/2)))) $percent
    fi
    sleep 1
done

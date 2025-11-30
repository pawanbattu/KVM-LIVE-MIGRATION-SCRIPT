#!/bin/bash
set -euo pipefail

# Arguments
SOURCE_VM="$1"
NEW_VM_NAME="$2"
DEST_IP="$3"
DEST_PORT="$4"
BANDWIDTH="$5"
DOWNTIME="$6"
SHARED="$7"
LOGFILE="$8"

XML_TMP="/tmp/${SOURCE_VM}_migration.xml"
MAIN_LOG="$LOGFILE"

echo "================ Live Migration Orchestration Started ================" | tee -a "$MAIN_LOG"
echo "$(date)" | tee -a "$MAIN_LOG"
echo "Source VM        : $SOURCE_VM" | tee -a "$MAIN_LOG"
echo "Rename to        : $NEW_VM_NAME" | tee -a "$MAIN_LOG"
echo "Destination      : $DEST_IP:$DEST_PORT" | tee -a "$MAIN_LOG"
echo "Bandwidth        : ${BANDWIDTH} Mbps" | tee -a "$MAIN_LOG"
echo "Downtime Max     : ${DOWNTIME} ms" | tee -a "$MAIN_LOG"
echo "Shared Storage   : $SHARED (1=yes,0=no)" | tee -a "$MAIN_LOG"
echo "Log File         : $MAIN_LOG" | tee -a "$MAIN_LOG"
echo "======================================================================" | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"

# ========== STEP 1: EXPORT XML ==========
echo "[1/5] Exporting XML from source VM..." | tee -a "$MAIN_LOG"
bash ./export_vm_xml.sh "$SOURCE_VM" "$XML_TMP"
echo "✔ XML exported to $XML_TMP" | tee -a "$MAIN_LOG"
sleep 1

# ========== STEP 2: HEALTH CHECK ==========
echo "[2/5] Running pre-migration checks..." | tee -a "$MAIN_LOG"
bash ./migration_check.sh "$SOURCE_VM" "$DEST_IP" "$DEST_PORT"
echo "✔ Pre-checks completed successfully" | tee -a "$MAIN_LOG"
sleep 1

# ========== STEP 3: LIVE MIGRATION ==========
echo "[3/5] Initiating live migration..." | tee -a "$MAIN_LOG"
bash ./migration_progress.sh "$SOURCE_VM" &
PROGRESS_PID=$!

set +e   # Do not abort on migration error so code handles result
bash ./live_migrate.sh "$NEW_VM_NAME" "$DEST_IP" "$DEST_PORT" "$BANDWIDTH" "$SOURCE_VM" "$DOWNTIME" "$SHARED" "$XML_TMP" "$MAIN_LOG"
RET=$?
set -e

kill "$PROGRESS_PID" >/dev/null 2>&1 || true
echo -e "\n" | tee -a "$MAIN_LOG"

if [ $RET -ne 0 ]; then
    echo "Migration FAILED — Return code $RET" | tee -a "$MAIN_LOG"
    echo "[4/5] Initiating rollback..." | tee -a "$MAIN_LOG"
    bash ./rollback_migration.sh "$DEST_IP" "$DEST_PORT" "$NEW_VM_NAME" | tee -a "$MAIN_LOG"
    echo "Migration aborted & rollback completed." | tee -a "$MAIN_LOG"
    rm -f "$XML_TMP"
    exit 1
fi

echo "✔ Migration succeeded!" | tee -a "$MAIN_LOG"

# ========== STEP 4: AUTO START ON DESTINATION + CLEANUP ON SOURCE ==========
echo "[4/5] Auto-starting VM on destination & cleaning source VM..." | tee -a "$MAIN_LOG"
bash ./post_cleanup_start.sh "$DEST_IP" "$DEST_PORT" "$NEW_VM_NAME" "$SOURCE_VM" | tee -a "$MAIN_LOG"
sleep 1

# ========== STEP 5: FINALIZE ==========
rm -f "$XML_TMP" 2>/dev/null || true

echo | tee -a "$MAIN_LOG"
echo "======================================================================" | tee -a "$MAIN_LOG"
echo "LIVE MIGRATION COMPLETED SUCCESSFULLY" | tee -a "$MAIN_LOG"
echo "New VM Active on: $DEST_IP ($NEW_VM_NAME)" | tee -a "$MAIN_LOG"
echo "Logs: $MAIN_LOG" | tee -a "$MAIN_LOG"
echo "$(date)" | tee -a "$MAIN_LOG"
echo "======================================================================" | tee -a "$MAIN_LOG"

exit 0

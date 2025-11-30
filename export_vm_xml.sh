#!/bin/bash
set -euo pipefail

VPS_NAME="$1"
OUTFILE="$2"

echo "Exporting XML for $VPS_NAME -> $OUTFILE"
virsh dumpxml "$VPS_NAME" > "$OUTFILE"
sed -i '/<uuid>.*<\/uuid>/d' "$OUTFILE"      
sed -i '/<name>.*<\/name>/d' "$OUTFILE"    
echo "XML exported"

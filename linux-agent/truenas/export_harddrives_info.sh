#!/bin/bash
# Export ZFS dataset and pool info for /mnt/Hard_Drives into JSON
set -e
OUT_DIR=/var/lib/menubar
OUT_FILE="$OUT_DIR/harddrives.json"
mkdir -p "$OUT_DIR"

DATASET=$(/sbin/zfs list -H -o name,mountpoint | awk -F$'\t' '$2=="/mnt/Hard_Drives"{print $1; exit}')
if [ -z "$DATASET" ]; then
  echo '{"error":"dataset not found"}' > "$OUT_FILE"
  exit 0
fi

read USED AVAIL <<< $(zfs list -H -o used,available -p "$DATASET")
POOL=${DATASET%%/*}
read PNAME PSIZE PALLOC PFREE <<< $(zpool list -H -o name,size,alloc,free "$POOL")

jq -n \
  --arg ds "$DATASET" \
  --arg used "$USED" \
  --arg avail "$AVAIL" \
  --arg pool "$PNAME" \
  --arg psize "$PSIZE" \
  --arg palloc "$PALLOC" \
  --arg pfree "$PFREE" \
  '{dataset:$ds,used:(($used|tonumber)),available:(($avail|tonumber)),pool:{name:$pool,size:(($psize|tonumber)),alloc:(($palloc|tonumber)),free:(($pfree|tonumber))}}' \
  > "$OUT_FILE"

chown root:root "$OUT_FILE" || true
chmod 0644 "$OUT_FILE" || true

exit 0

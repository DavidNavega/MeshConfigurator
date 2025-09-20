#!/usr/bin/env bash
set -euo pipefail
PROTO_DIR="${1:-../protobufs}"
OUT_DIR="lib/proto"
mkdir -p "$OUT_DIR"
protoc -I "$PROTO_DIR" --dart_out="$OUT_DIR"   "$PROTO_DIR/meshtastic/mesh.proto"   "$PROTO_DIR/meshtastic/admin.proto"   "$PROTO_DIR/meshtastic/channel.proto"   "$PROTO_DIR/meshtastic/config.proto"   "$PROTO_DIR/meshtastic/module_config.proto"
echo "Generados en $OUT_DIR (recuerda usar el tag que coincide con tu firmware)."

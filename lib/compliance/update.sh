#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

DIR="${1:-$(dirname "${BASH_SOURCE[0]}")}"

L_SPDX=$(mktemp /tmp/licenses.spdx.XXXXXX.json)
E_SPDX=$(mktemp /tmp/exceptions.spdx.XXXXXX.json)
trap "rm $L_SPDX $E_SPDX" EXIT

curl -sL https://spdx.org/licenses/licenses.json -o "$L_SPDX"
curl -sL https://spdx.org/licenses/exceptions.json -o "$E_SPDX"

jq -Scn \
  --slurpfile l "$L_SPDX" \
  --slurpfile e "$E_SPDX" \
  --slurpfile ov "$DIR/overrides.json" \
  -f "$DIR/update.jq" \
  > "$DIR/by-spdx.json"

#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

BASE_DIR="${1:-$PWD/lib/compliance}"

L_SPDX=$(mktemp /tmp/licenses.spdx.XXXXXX.json)
E_SPDX=$(mktemp /tmp/exceptions.spdx.XXXXXX.json)
trap "rm $L_SPDX $E_SPDX" EXIT

curl -sL https://spdx.org/licenses/licenses.json  -o "$L_SPDX"
curl -sL https://spdx.org/licenses/exceptions.json -o "$E_SPDX"

jq -Scn \
  --slurpfile l  "$L_SPDX" \
  --slurpfile e  "$E_SPDX" \
  --slurpfile lo "$BASE_DIR/licenses.overrides.json" \
  --slurpfile eo "$BASE_DIR/exceptions.overrides.json" '
  def norm(d): with_entries(
    (.value.nixFree // .value.osiApproved // .value.fsfLibre // d) as $nf |
    .value = { name: .key
             , type: .value.type
             , osiApproved: (.value.osiApproved // d), fsfLibre: (.value.fsfLibre // d)
             , nixFree: $nf, nixRedistributable: (.value.nixRedistributable // $nf) });
  { spdxVersion: $l[0].licenseListVersion
  , spdxDate:    $l[0].releaseDate
  , bySpdx:
      ( INDEX($l[0].licenses[]; .licenseId)
      | map_values({ type: "license", osiApproved: .isOsiApproved, fsfLibre: .isFsfLibre
                   , nixRedistributable: (.isOsiApproved or .isFsfLibre) })
      * $lo[0] | norm(false) )
      +
      ( INDEX($e[0].exceptions[]; .licenseExceptionId) | map_values({type: "exception"})
      * $eo[0] | norm(true) )
  }
' > "$BASE_DIR/by-spdx.json"

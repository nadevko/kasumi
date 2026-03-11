#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

BASE_DIR="${1:-$PWD/lib/compliance}"

SPDX="$BASE_DIR/spdx.json"
L_SPDX="$BASE_DIR/licenses.spdx.json"
E_SPDX="$BASE_DIR/exceptions.spdx.json"

L_NIX="$BASE_DIR/licenses.nix.json"
E_NIX="$BASE_DIR/exceptions.nix.json"

L="$BASE_DIR/licenses.json"
E="$BASE_DIR/exceptions.json"

[[ ! -e $L_SPDX ]] && curl -L https://spdx.org/licenses/licenses.json -o "$L_SPDX"
[[ ! -e $E_SPDX ]] && curl -L https://spdx.org/licenses/exceptions.json -o "$E_SPDX"

jq '{
  spdxVersion: .licenseListVersion,
  spdxDate: .releaseDate
}' "$L_SPDX" > "$SPDX"

jq -Sc --slurpfile nix "$L_NIX" '
  .licenses | reduce .[] as $l ({}; 
    . + { ($l.licenseId): (
    {name: $l.name}
    | . + (if $l.isOsiApproved == false then {osiApproved: false} else {} end)
    | . + (if $l.isFsfLibre == false then {fsfLibre: false} else {} end)
    | . + (if $l.isDeprecatedLicenseId == true then {deprecated: true} else {} end)
    * ($nix[0].licenses[$l.licenseId] // {})) }
  )
' "$L_SPDX" > "$L"

jq -Sc --slurpfile nix "$E_NIX" '
  .exceptions | reduce .[] as $e ({};
    . + { ($e.licenseExceptionId): (
    {name: $e.name}
    | . + (if $e.isDeprecatedLicenseId == true then {deprecated: true} else {} end)
    * ($nix[0].exceptions[$e.licenseExceptionId] // {})) }
  )
' "$E_SPDX" > "$E"

rm "$L_SPDX" "$E_SPDX"

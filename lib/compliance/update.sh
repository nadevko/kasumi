#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

BASE_DIR="${1:-$PWD/lib/compliance}"
OV="$BASE_DIR/overrides.json"

L_SPDX=$(mktemp /tmp/licenses.spdx.XXXXXX.json)
E_SPDX=$(mktemp /tmp/exceptions.spdx.XXXXXX.json)
trap "rm $L_SPDX $E_SPDX" EXIT

curl -sL https://spdx.org/licenses/licenses.json  -o "$L_SPDX"
curl -sL https://spdx.org/licenses/exceptions.json -o "$E_SPDX"

jq -Scn \
  --slurpfile l  "$L_SPDX" \
  --slurpfile e  "$E_SPDX" \
  --slurpfile ov "$OV" '
  def defaults(ex):
    (.nixFree // .osiApproved // .fsfLibre // ex) as $nf |
    { osiApproved:        (.osiApproved // ex)
    , fsfLibre:           (.fsfLibre // ex)
    , nixFree:            $nf
    , nixRedistributable: (.nixRedistributable // $nf)
    , exception:          ex
    };
  def versioned: capture("^(?<prefix>.*)-(?<ver>\\d+\\.\\d+)$");
  def semver: split(".") | map(tonumber);
  def gnulike: test("^(GPL|LGPL|AGPL|GFDL)-(\\d+\\.\\d+)");

  INDEX($l[0].licenses[];  .licenseId)           as $lIdx |
  INDEX($e[0].exceptions[]; .licenseExceptionId) as $eIdx |

  ( $lIdx | to_entries | map(.value = (
        { osiApproved: .value.isOsiApproved, fsfLibre: .value.isFsfLibre
        , nixRedistributable: (.value.isOsiApproved or .value.isFsfLibre)
        } * ($ov[0].licenses[.key] // {}) | defaults(false)
      )) | from_entries
    + ( $ov[0].licenses // {}
        | with_entries(select($lIdx[.key] == null))
        | map_values(defaults(false))
      )
  ) as $licenses |

  ( $eIdx | to_entries | map(.value = (
        ({} * ($ov[0].exceptions[.key] // {})) | defaults(true)
      )) | from_entries
    + ( $ov[0].exceptions // {}
        | with_entries(select($eIdx[.key] == null))
        | map_values(defaults(true))
      )
  ) as $exceptions |

  ( $licenses + $exceptions
  | with_entries(.value = { id: .key, type: "spdx" } + .value)
  ) as $all |

  ( [ $all | to_entries[]
      | (.key | versioned) as $p
      | select($p != null and (.key | gnulike | not))
      | { key: $p.prefix, value: { key: .key, ver: $p.ver } }
    ]
    | group_by(.key)
    | map({ key: .[0].key, value: map(.value) })
    | from_entries
  ) as $byPrefix |

  ( $all | with_entries(
      (.key | versioned) as $p |
      if $p == null or (.key | gnulike) then empty
      else .value = ( $byPrefix[$p.prefix]
          | map(select((.ver | semver) >= ($p.ver | semver)) | .key)
        )
      end
    )
  ) as $laterOv |

  $all | with_entries(
    if .key | gnulike then .value.later = null
    elif ($laterOv[.key] | length) > 1 then .value.later = $laterOv[.key]
    else . end
  )
  | { spdxVersion: $l[0].licenseListVersion
    , spdxDate:    $l[0].releaseDate
    , bySpdx:      .
    }
' > "$BASE_DIR/by-spdx.json"

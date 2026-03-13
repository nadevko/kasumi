final: prev:
let
  inherit (final.filesystem) importJson;
  inherit (final.attrs) mapAttrs;
  inherit (final.fetchers) fetchUrl;

  inherit (final.compliance) licenses-by-spdx;
in
{
  # --- spdx ------------------------------------------------------------------
  inherit (importJson ./spdx.json) spdxVersion spdxDate;

  licenses-by-spdx =
    mapAttrs (
      id: v:
      let
        url = "https://spdx.org/licenses/" + id;
        default = v.osiApproved or v.fsfLibre or true;
      in
      v
      // {
        inherit id;
        htmlUrl = url + ".html";
        # details = importJson <| fetchUrl { url = url + ".json"; };
        free = v.free or default;
        redistributable = v.redistributable default;
      }
    )
    <| importJson ./licenses.json;

  exceptions-by-spdx =
    mapAttrs (
      id: v:
      let
        url = "https://spdx.org/licenses/" + id;
      in
      v
      // {
        inherit id;
        htmlUrl = url + ".html";
        details = importJson <| fetchUrl { url = url + ".json"; };
      }
    )
    <| importJson ./exceptions.json;

  # --- aliases ---------------------------------------------------------------
  # for licenses with more than 100 mentions on nixpkgs at 2026-03-06 04:56:59

  licenses = licenses-by-spdx // {
    mit = licenses-by-spdx."MIT"; # 6459
    asl2 = licenses-by-spdx."Apache-2.0"; # 2991
    gpl2plus = licenses-by-spdx."GPL-2.0-or-later"; # 2201
    gpl3plus = licenses-by-spdx."GPL-3.0-or-later"; # 1978
    bsd3 = licenses-by-spdx."BSD-3-Clause"; # 1471
    gpl3only = licenses-by-spdx."GPL-3.0-only"; # 1350
    gpl2only = licenses-by-spdx."GPL-2.0-only"; # 971
    gpl3 = licenses-by-spdx."GPL-3.0"; # 801
    bsd2 = licenses-by-spdx."BSD-2-Clause"; # 690
    gpl2 = licenses-by-spdx."GPL-2.0"; # 575
    lgpl21plus = licenses-by-spdx."LGPL-2.1-or-later"; # 423
    mpl2 = licenses-by-spdx."MPL-2.0"; # 387
    agpl3only = licenses-by-spdx."AGPL-3.0-only"; # 382
    ofl11 = licenses-by-spdx."OFL-1.1"; # 358
    isc = licenses-by-spdx."ISC"; # 316
    lgpl21 = licenses-by-spdx."LGPL-2.1"; # 269
    lgpl2plus = licenses-by-spdx."LGPL-2.0-or-later"; # 268
    agpl3plus = licenses-by-spdx."AGPL-3.0-or-later"; # 251
    lgpl3plus = licenses-by-spdx."LGPL-3.0-or-later"; # 246
    zlib = licenses-by-spdx."Zlib"; # 150
    cc0 = licenses-by-spdx."CC0-1.0"; # 147
    unlicense = licenses-by-spdx."Unlicense"; # 138
    x11 = licenses-by-spdx."X11"; # 137
    lgpl3only = licenses-by-spdx."LGPL-3.0-only"; # 127
    hpndSellVariant = licenses-by-spdx."HPND-sell-variant"; # 125
    lgpl3 = licenses-by-spdx."LGPL-3.0"; # 123
    lgpl21only = licenses-by-spdx."LGPL-2.1-only"; # 123
    bsl10 = licenses-by-spdx."BSL-1.0"; # 108
  };
}

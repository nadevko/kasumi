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

  # --- aliases -------------------------------------------------------------------
  licenses = licenses-by-spdx // {
    # MIT License
    mit = licenses-by-spdx."MIT";
    mit0 = licenses-by-spdx."MIT-0";

    # Apache License
    asl1 = licenses-by-spdx."Apache-1.0";
    asl11 = licenses-by-spdx."Apache-1.1";
    asl2 = licenses-by-spdx."Apache-2.0";

    # BSD License Family
    bsd0 = licenses-by-spdx."0BSD";
    bsd1 = licenses-by-spdx."BSD-1-Clause";
    bsd2 = licenses-by-spdx."BSD-2-Clause";
    bsd3 = licenses-by-spdx."BSD-3-Clause";
    bsd3clear = licenses-by-spdx."BSD-3-Clause-Clear";
    bsd4 = licenses-by-spdx."BSD-4-Clause";

    # FSF License Family
    agpl1only = licenses-by-spdx."AGPL-1.0-only";
    agpl1plus = licenses-by-spdx."AGPL-1.0-or-later";
    agpl3only = licenses-by-spdx."AGPL-3.0-only";
    agpl3plus = licenses-by-spdx."AGPL-3.0-or-later";
    gfdl11only = licenses-by-spdx."GFDL-1.1-only";
    gfdl11plus = licenses-by-spdx."GFDL-1.1-or-later";
    gfdl12only = licenses-by-spdx."GFDL-1.2-only";
    gfdl12plus = licenses-by-spdx."GFDL-1.2-or-later";
    gfdl13only = licenses-by-spdx."GFDL-1.3-only";
    gfdl13plus = licenses-by-spdx."GFDL-1.3-or-later";
    gpl1only = licenses-by-spdx."GPL-1.0-only";
    gpl1plus = licenses-by-spdx."GPL-1.0-or-later";
    gpl2only = licenses-by-spdx."GPL-2.0-only";
    gpl2plus = licenses-by-spdx."GPL-2.0-or-later";
    gpl3only = licenses-by-spdx."GPL-3.0-only";
    gpl3plus = licenses-by-spdx."GPL-3.0-or-later";
    lgpl21only = licenses-by-spdx."LGPL-2.1-only";
    lgpl21plus = licenses-by-spdx."LGPL-2.1-or-later";
    lgpl2only = licenses-by-spdx."LGPL-2.0-only";
    lgpl2plus = licenses-by-spdx."LGPL-2.0-or-later";
    lgpl3only = licenses-by-spdx."LGPL-3.0-only";
    lgpl3plus = licenses-by-spdx."LGPL-3.0-or-later";

    # SIL Open Font License
    ofl1 = licenses-by-spdx."OFL-1.0";
    ofl11 = licenses-by-spdx."OFL-1.1";

    # Mozilla Public License
    mpl1 = licenses-by-spdx."MPL-1.0";
    mpl11 = licenses-by-spdx."MPL-1.1";
    mpl2 = licenses-by-spdx."MPL-2.0";

    # Academic Free License
    afl11 = licenses-by-spdx."AFL-1.1";
    afl12 = licenses-by-spdx."AFL-1.2";
    afl2 = licenses-by-spdx."AFL-2.0";
    afl21 = licenses-by-spdx."AFL-2.1";
    afl3 = licenses-by-spdx."AFL-3.0";

    # Eclipse Public license
    epl1 = licenses-by-spdx."EPL-1.0";
    epl11 = licenses-by-spdx."EPL-1.1";
    epl2 = licenses-by-spdx."EPL-2.0";

    # Artistic License
    artistic1 = licenses-by-spdx."Artistic-1.0";
    artistic2 = licenses-by-spdx."Artistic-2.0";

    # Open Software License
    osl1 = licenses-by-spdx."OSL-1.0";
    osl11 = licenses-by-spdx."OSL-1.1";
    osl2 = licenses-by-spdx."OSL-2.0";
    osl21 = licenses-by-spdx."OSL-2.1";
    osl3 = licenses-by-spdx."OSL-3.0";

    # European Union Public License
    eupl1 = licenses-by-spdx."EUPL-1.0";
    eupl11 = licenses-by-spdx."EUPL-1.1";
    eupl12 = licenses-by-spdx."EUPL-1.2";

    # etc
    bsl1 = licenses-by-spdx."BSL-1.0";
    cc0 = licenses-by-spdx."CC-0.1";
    cpl1 = licenses-by-spdx."CPL-1.0";
    isc = licenses-by-spdx."ISC";
    mspl = licenses-by-spdx."MS-PL";
    postgresql = licenses-by-spdx."PostgreSQL";
    unlicense = licenses-by-spdx."Unlicense";
    upl = licenses-by-spdx."UPL-1.0";
    wtfpl = licenses-by-spdx."WTFPL";
    zlib = licenses-by-spdx."Zlib";
  };
}

final: prev:
let
  inherit (final.filesystem) importJson;

  inherit (final.compliance) license-by-spdx;
in
{
  # --- spdx ------------------------------------------------------------------
  inherit (importJson ./spdx.json) spdxVersion spdxDate;

  license-by-spdx = importJson ./licenses.json;
  exception-by-spdx = importJson ./exceptions.json;

  # -- uncommon licenses ------------------------------------------------------
  makeFreeLicense = { };

  makeUnfreeLicense = { };

  # --- aliases -------------------------------------------------------------------
  licenses = license-by-spdx // {
    # MIT
    mit = license-by-spdx."MIT";
    mit0 = license-by-spdx."MIT-0";

    # ASL
    asl1 = license-by-spdx."Apache-1.0";
    asl11 = license-by-spdx."Apache-1.1";
    asl2 = license-by-spdx."Apache-2.0";

    # BSD
    bsd0 = license-by-spdx."0BSD";
    bsd1 = license-by-spdx."BSD-1-Clause";
    bsd2 = license-by-spdx."BSD-2-Clause";
    bsd3 = license-by-spdx."BSD-3-Clause";
    bsd4 = license-by-spdx."BSD-4-Clause";

    # FSF
    agpl1only = license-by-spdx."AGPL-1.0-only";
    agpl1plus = license-by-spdx."AGPL-1.0-or-later";
    agpl2only = license-by-spdx."AGPL-2.0-only";
    agpl2plus = license-by-spdx."AGPL-2.0-or-later";
    agpl3only = license-by-spdx."AGPL-3.0-only";
    agpl3plus = license-by-spdx."AGPL-3.0-or-later";
    gfdl11only = license-by-spdx."GFDL-1.1-only";
    gfdl11plus = license-by-spdx."GFDL-1.1-or-later";
    gfdl12only = license-by-spdx."GFDL-1.2-only";
    gfdl12plus = license-by-spdx."GFDL-1.2-or-later";
    gfdl13only = license-by-spdx."GFDL-1.3-only";
    gfdl13plus = license-by-spdx."GFDL-1.3-or-later";
    gpl1only = license-by-spdx."GPL-1.0-only";
    gpl1plus = license-by-spdx."GPL-1.0-or-later";
    gpl2only = license-by-spdx."GPL-2.0-only";
    gpl2plus = license-by-spdx."GPL-2.0-or-later";
    gpl3only = license-by-spdx."GPL-3.0-only";
    gpl3plus = license-by-spdx."GPL-3.0-or-later";
    lgpl21only = license-by-spdx."LGPL-2.1-only";
    lgpl21plus = license-by-spdx."LGPL-2.1-or-later";
    lgpl2only = license-by-spdx."LGPL-2.0-only";
    lgpl2plus = license-by-spdx."LGPL-2.0-or-later";
    lgpl3only = license-by-spdx."LGPL-3.0-only";
    lgpl3plus = license-by-spdx."LGPL-3.0-or-later";

    # OFL
    ofl1 = license-by-spdx."OFL-1.0";
    ofl11 = license-by-spdx."OFL-1.1";

    # MPL
    mpl1 = license-by-spdx."MPL-1.0";
    mpl11 = license-by-spdx."MPL-1.1";
    mpl2 = license-by-spdx."MPL-2.0";

    # AFL
    afl11 = license-by-spdx."AFL-1.1";
    afl12 = license-by-spdx."AFL-1.2";
    afl2 = license-by-spdx."AFL-2.0";
    afl21 = license-by-spdx."AFL-2.1";
    afl3 = license-by-spdx."AFL-3.0";

    # EPL
    epl1 = license-by-spdx."EPL-1.0";
    epl11 = license-by-spdx."EPL-1.1";
    epl2 = license-by-spdx."EPL-2.0";

    # etc
    bsl1 = license-by-spdx."BSL-1.0";
    cc0 = license-by-spdx."CC0-1.0";
    cpl1 = license-by-spdx."CPL-1.0";
    isc = license-by-spdx."ISC";
    mspl = license-by-spdx."MS-PL";
    postgresql = license-by-spdx."PostgreSQL";
    unlicense = license-by-spdx."Unlicense";
    zlib = license-by-spdx."Zlib";
  };
}

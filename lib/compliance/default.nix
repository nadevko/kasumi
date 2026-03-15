final: prev:
let
  inherit (final.attrs) genAttrs pair;
  inherit (final.debug) throw;
  inherit (final.filesystem) importJson;
  inherit (final.strings) joinSep;
  inherit (final.lists) all any pluck;
  inherit (final.prelude)
    id
    isString
    boolAnd
    boolOr
    typeOf
    flip
    ;

  inherit (final.compliance)
    exceptions
    getException
    getLicense
    getSpdx
    isSpdx
    licenses
    licensesOrLater
    spdxCompose
    spdxComposeList
    spdxLicenseComposer
    ;
in
{
  # --- SPDX lists ------------------------------------------------------------
  inherit (importJson ./spdx.json) spdxVersion spdxDate;

  licenses = importJson ./licenses.json;
  exceptions = importJson ./exceptions.json;

  isSpdx = x: x ? type && x.type == "spdx";

  getSpdx =
    set: selfName: x:
    if isString x then
      set.${x} or (throw "compliance.${selfName}: unknown spdx ${x}")
    else
      assert isSpdx x || throw "compliance.${selfName}: spdx or id are expected but got ${typeOf x}";
      x;

  getLicense = getSpdx licenses "getLicense";
  getException = getSpdx exceptions "getException";

  # --- SPDX Combinators ------------------------------------------------------
  spdxCompose =
    getA: getB: join: comparator: a: b:
    let
      a' = getA a;
      b' = getB b;
    in
    {
      type = "spdx";
      id = join a'.id b'.id;
      osiApproved = comparator a'.osiApproved b'.osiApproved;
      fsfLibre = comparator a'.fsfLibre b'.fsfLibre;
      nixFree = comparator a'.nixFree b'.nixFree;
      nixRedistributable = comparator a'.nixRedistributable b'.nixRedistributable;
    };

  spdxLicenseComposer = spdxCompose getLicense getLicense;
  spdxAnd = spdxLicenseComposer (a: b: "(${a} and ${b})") boolAnd;
  spdxOr = spdxLicenseComposer (a: b: "(${a} or ${b})") boolOr;
  spdxWith = spdxCompose getLicense getException (a: b: "(${a} with ${b})") boolAnd;

  spdxComposeList =
    joinId: comparator: xs:
    let
      xs' = map getLicense xs;
    in
    {
      type = "spdx";
      id = joinId <| pluck "id" xs';
      osiApproved = comparator <| pluck "osiApproved" xs';
      fsfLibre = comparator <| pluck "fsfLibre" xs';
      nixFree = comparator <| pluck "nixFree" xs';
      nixRedistributable = comparator <| pluck "nixRedistributable" xs';
    };

  spdxAll = spdxComposeList (xs: "(${joinSep " and " xs})") <| all id;
  spdxAny = spdxComposeList (xs: "(${joinSep " or " xs})") <| any id;

  # --- SPDX plus -------------------------------------------------------------
  spdxPlus = x: licensesOrLater.${(getLicense x).id};

  licensesOrLater =
    let
      gnu = [
        "GPL-1.0"
        "GPL-2.0"
        "GPL-3.0"
        "LGPL-2.0"
        "LGPL-2.1"
        "LGPL-3.0"
        "AGPL-1.0"
        "AGPL-3.0"
        "GFDL-1.1"
        "GFDL-1.2"
        "GFDL-1.3"
      ];
    in
    genAttrs (id: id + "-or-later" |> getLicense |> pair id) gnu
    // genAttrs (flip pair getLicense) (map (id: id + "-or-later") gnu)
    // genAttrs (id: id + "-or-later" |> getLicense |> pair (id + "-only")) gnu;
}

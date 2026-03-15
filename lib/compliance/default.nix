final: prev:
let
  inherit (final.sets) assocBy assocNames pair;
  inherit (final.debug) throw;
  inherit (final.filesystem) importJson;
  inherit (final.strings) joinSep;
  inherit (final.lists) all any pluck;
  inherit (final.prelude)
    id
    isString
    land
    lor
    typeOf
    ;

  inherit (final.compliance)
    bySpdx
    getSpdx
    isSpdx
    licensesOrLater
    spdxCompose
    spdxComposeList
    spdxAnd
    spdxOr
    spdxWith
    ;
in
{
  # --- SPDX lists ------------------------------------------------------------
  inherit (importJson ./by-spdx.json) bySpdx spdxVersion spdxDate;

  isSpdx = x: x ? type && (x.type == "license" || x.type == "exception");

  getSpdx =
    n:
    if isString n then
      bySpdx.${n} or (throw "compliance.getSpdx: unknown spdx '${n}'")
    else
      assert isSpdx n || throw "compliance.getSpdx: spdx or name are expected but got '${typeOf n}'";
      n;
  
  spdx = {
    __findFile = _: getSpdx;
    __mul = spdxAnd;
    __lessThan = spdxOr;
    __div = spdxWith;
    # __sub = spdxPlus;
  };

  # --- SPDX Combinators ------------------------------------------------------
  spdxCompose =
    join: comparator: a: b:
    let
      a' = getSpdx a;
      b' = getSpdx b;
    in
    {
      type = "license";
      name = join a'.name b'.name;
      osiApproved = comparator a'.osiApproved b'.osiApproved;
      fsfLibre = comparator a'.fsfLibre b'.fsfLibre;
      nixFree = comparator a'.nixFree b'.nixFree;
      nixRedistributable = comparator a'.nixRedistributable b'.nixRedistributable;
    };

  spdxAnd = spdxCompose (a: b: "(${a} and ${b})") land;
  spdxWith = spdxCompose (a: b: "(${a} with ${b})") land;
  spdxOr = spdxCompose (a: b: "(${a} or ${b})") lor;

  spdxComposeList =
    joinId: comparator: xs:
    let
      xs' = map getSpdx xs;
    in
    {
      type = "license";
      name = joinId <| pluck "name" xs';
      osiApproved = comparator <| pluck "osiApproved" xs';
      fsfLibre = comparator <| pluck "fsfLibre" xs';
      nixFree = comparator <| pluck "nixFree" xs';
      nixRedistributable = comparator <| pluck "nixRedistributable" xs';
    };

  spdxAll = spdxComposeList (xs: "(${joinSep " and " xs})") <| all id;
  spdxAny = spdxComposeList (xs: "(${joinSep " or " xs})") <| any id;

  # --- SPDX plus -------------------------------------------------------------
  spdxPlus = x: licensesOrLater.${(getSpdx x).name};

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
    assocNames (n: getSpdx <| n + "-or-later") gnu
    // assocNames getSpdx (map (n: n + "-or-later") gnu)
    // assocBy (n: n + "-or-later" |> getSpdx |> pair (n + "-only")) gnu;
}

final: prev:
let
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
    ;

  inherit (final.compliance)
    exceptions
    getException
    getLicense
    getSpdx
    isSpdx
    licenses
    spdxCompose
    spdxComposeList
    spdxLicenseComposer
    ;
in
{
  inherit (importJson ./spdx.json) spdxVersion spdxDate;

  licenses = importJson ./licenses.json;
  exceptions = importJson ./exceptions.json;

  isSpdx = x: x ? type && x.type == "spdx";

  getSpdx =
    set: selfName: x:
    if isString x then
      set.${x} or (throw "licenses.${selfName}: unknown spdx ${x}")
    else
      assert isSpdx x || throw "licenses.${selfName}: spdx or id are expected but got ${typeOf x}";
      x;

  getLicense = getSpdx licenses "getLicense";
  getException = getSpdx exceptions "getException";

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
}

final: prev:
let
  inherit (final.lists)
    head
    at
    take
    replicate
    last
    slice
    ;
  inherit (final.types) isStr isList;
  inherit (final.prelude) compose;
  inherit (final.derivations) tryStripContext;
  inherit (final.numeric) max;
  inherit (final.strings)
    splitString
    joinSep
    removePrefix
    match
    length
    joinMap
    split
    ;

  inherit (final.meta)
    splitVersion
    compareVersions
    splitDrvName
    padVersionSep
    versionNumeric
    versionOlder
    idPname
    idVersion
    ;
in
prev.meta or { }
// {
  # --- derivation name -------------------------------------------------------
  idPname = x: (splitDrvName x).name;
  idVersion = x: (splitDrvName x).version;

  pname = x: if isStr x then idPname x else x.pname or (idPname x.name);
  version = x: if isStr x then idVersion x else x.version or (idVersion x.name);

  pnameFromUrl =
    url: sep:
    let
      filename = last <| splitString "/" url;
      name = head <| splitString sep filename;
    in
    assert name != filename;
    name;

  # --- version splits --------------------------------------------------------
  major = compose head splitVersion;
  minor = ver: at (splitVersion ver) 1;
  patch = ver: at (splitVersion ver) 2;
  majorMinor = ver: splitVersion ver |> take 2 |> joinSep ".";

  versionNumeric = ver: head <| splitString "-" ver;
  versionSuffix = ver: removePrefix (versionNumeric ver) ver;

  semver =
    ver:
    let
      vers = splitVersion ver;
      numeric = versionNumeric ver;
    in
    {
      major = head vers;
      minor = at vers 1;
      patch = at vers 2;
      inherit numeric;
      suffix = removePrefix numeric ver;
      __toString = _: ver;
    };

  # --- comparators -----------------------------------------------------------
  versionOlder = a: b: compareVersions b a == 1;
  versionAtLeast = a: b: !versionOlder a b;

  # --- normalisation ---------------------------------------------------------
  stripDrvName =
    str:
    if length str <= 207 && match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*" str != null then
      tryStripContext str
    else
      tryStripContext str
      |> match ''\.*(.*)''
      |> (x: at x 0)
      |> split "[^[:alnum:]+._?=-]+"
      |> joinMap (s: if isList s then "-" else s)
      |> (x: slice (max (length x - 207) 0) (-1) x)
      |> (x: if length x == 0 then "unknown" else x);

  padVersionSep =
    sep: n: ver:
    let
      numeric = versionNumeric ver;
    in
    joinSep sep (take n <| splitVersion numeric ++ replicate n "0") + (removePrefix numeric ver);

  padVersion = padVersionSep ".";
}

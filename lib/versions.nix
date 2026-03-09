final: prev:
let
  inherit (final.lists)
    head
    at
    take
    replicate
    ;
  inherit (final.prelude) compose;
  inherit (final.strings) splitString joinSep removePrefix;

  inherit (final.versions) splitVersion padVersionSep versionNumeric;
in
prev.versions or { }
// {
  # --- getters (as strings) --------------------------------------------------
  major = compose head splitVersion;
  minor = ver: at (splitVersion ver) 1;
  patch = ver: at (splitVersion ver) 2;
  majorMinor = ver: splitVersion ver |> take 2 |> joinSep ".";

  versionNumeric = ver: splitString "-" ver |> head;
  versionSuffix = ver: removePrefix (versionNumeric ver) ver;

  semver =
    ver:
    let
      ver = splitVersion ver;
      numeric = versionNumeric ver;
    in
    {
      major = head ver;
      minor = at ver 1;
      patch = at ver 2;
      inherit numeric;
      suffix = removePrefix numeric ver;
    };

  # --- normalisation ---------------------------------------------------------
  padVersionSep =
    sep: n: ver:
    let
      numeric = versionNumeric ver;
    in
    joinSep sep (take n <| splitVersion numeric ++ replicate n "0") + (removePrefix numeric ver);

  padVersion = padVersionSep ".";
}

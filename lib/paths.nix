final: prev:
let
  inherit (final.lists) head;
  inherit (final.strings)
    hasPrefix
    hasSuffix
    removeSuffix
    isStrLike
    slice
    match
    ;
  inherit (final.prelude) eq;

  inherit (final.paths)
    isDir
    isNix
    isHidden
    isVisible
    nixStorePath
    dirname
    ;
in
prev.paths or { }
// {
  stemOf =
    n:
    let
      matches = match ''(.*)\.[^.]+$'' n;
    in
    if matches == null then n else head matches;

  stemOfNix = removeSuffix ".nix";

  isDir = eq "directory";
  isNix = hasSuffix ".nix";
  isHidden = hasPrefix ".";
  isVisible = n: !isHidden n;

  isVisibleNix = n: _: isVisible n && isNix n;
  isVisibleDir = n: type: isVisible n && isDir type;

  isStoreLike =
    x:
    isStrLike x
    && (
      let
        str = toString x;
      in
      slice 0 1 str == "/"
      && (
        dirname str == nixStorePath
        #! temp CA-drvs workaround https://github.com/NixOS/nix/issues/12361
        || match "/[0-9a-z]{52}" str != null
      )
    );
}

final: prev:
let
  inherit (builtins) match head;

  inherit (final.strings) hasPrefix hasSuffix removeSuffix;

  inherit (final.trivial) eq;

  inherit (final.paths)
    isDir
    isNix
    isHidden
    isVisible
    ;
in
{
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
}

final: prev:
let
  inherit (builtins) isAttrs elem;

  inherit (final.strings) hasPrefix;
  inherit (final.attrs) mbindAttrs bindAttrs singletonPair;
  inherit (final.overlays) nestOverlayl nestOverlayr;

  inherit (final.lib)
    genLibAliasesPred
    genLibAliasesWithout
    forkLibAs
    augmentLibAs
    ;
in
{
  genLibAliasesPred =
    pred:
    mbindAttrs (
      n: v:
      if isAttrs v -> pred n v then
        [ ]
      else
        bindAttrs (n: v: if isAttrs v || hasPrefix "_" n then [ ] else singletonPair n v) v
    );

  genLibAliasesWithout = blacklist: genLibAliasesPred (n: _: elem n blacklist || hasPrefix "_" n);

  genLibAliases = genLibAliasesWithout [
    "systems"
    "licenses"
    "fetchers"
    "generators"
    "cli"
    "network"
    "kernel"
    "types"
    "maintainers"
    "features"
    "teams"
  ];

  forkLibAs = nestOverlayr "lib";
  forkLib = forkLibAs "lib";
  augmentLibAs = nestOverlayl "lib";
  augmentLib = augmentLibAs "lib";
}

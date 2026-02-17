final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.systems) flakeExposed;
  inherit (prev.attrsets) genAttrs;

  inherit (final.attrsets) genAttrsBy;
  inherit (final.trivial) id;
in
rec {
  flakeSystems = flakeExposed;

  importFlakePkgs =
    flake: config: system:
    if config == { } then
      flake.legacyPackages.${system}
    else
      import flake <| { inherit system; } // (if isFunction config then config system else config);

  forAllSystems = genAttrs flakeSystems;
  forSystems = genAttrs;

  forAllPkgs = forPkgs flakeSystems;
  forPkgs =
    systems: flake: config:
    genAttrsBy (importFlakePkgs flake config) systems;

  importPkgsFor =
    systems: flake: config:
    genAttrsBy (importFlakePkgs flake config) systems id;
  importPkgsForAll = importPkgsFor flakeSystems;
}

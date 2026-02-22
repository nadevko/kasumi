final: _:
let
  inherit (builtins) elem;

  inherit (final.derivations) isDerivation;
in
{
  isDerivation = v: v.type or null == "derivation";

  isSupportedDerivation =
    system: v:
    isDerivation v
    && !(v.meta.broken or false)
    && (v.meta ? badPlatforms -> !elem system v.meta.badPlatforms)
    && (v.meta ? platforms -> elem system v.meta.platforms);
}

final: prev:
let
  inherit (final.lists) elem slice;

  inherit (final.derivations) isDerivation;
in
{
  # --- context manipulations -------------------------------------------------
  cloneContext = src: target: slice 0 0 src + target;

  # --- types -----------------------------------------------------------------
  isDerivation = v: v.type or null == "derivation";

  isSupportedDerivation =
    system: v:
    isDerivation v
    && !(v.meta.broken or false)
    && (v.meta ? badPlatforms -> !elem system v.meta.badPlatforms)
    && (v.meta ? platforms -> elem system v.meta.platforms);
}

final: prev:
let
  inherit (final.prelude) compose isFunctor;
  inherit (final.reflect)
    inImpure
    getEnv
    functionArgs
    setAnnotation
    getAnnotation
    isAnnotated
    ;
in
prev.reflect or { }
// {
  # --- purity state ----------------------------------------------------------
  inNixShell = getEnv "IN_NIX_SHELL" != "";
  inImpure = builtins ? currentSystem;
  inPure = !inImpure;

  # --- annotations -----------------------------------------------------------
  isAnnotated = f: isFunctor f && f ? _functorArgs;
  getAnnotation = f: if isAnnotated f then f._functorArgs else functionArgs f;

  setAnnotation = args: f: {
    __functor = _: f;
    _functorArgs = args;
  };

  inheritAnnotationFrom = compose setAnnotation getAnnotation;
}

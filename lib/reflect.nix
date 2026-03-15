final: prev:
let
  inherit (final.prelude) compose isFunctor;
  inherit (final.reflect)
    inImpure
    getEnv
    getLambdaArgs
    annotateLambda
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
  getAnnotation = f: if isAnnotated f then f._functorArgs else getLambdaArgs f;

  annotateLambda = args: f: {
    __functor = _: f;
    _functorArgs = args;
  };

  inheritAnnotationFrom = compose annotateLambda getAnnotation;
}

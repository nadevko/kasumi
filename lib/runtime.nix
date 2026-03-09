final: prev:
let
  inherit (final.runtime) inImpure getEnv;
  inherit (final.types) isFunction;
in
prev.runtime or {} // {
  # --- purity state ----------------------------------------------------------
  inNixShell = getEnv "IN_NIX_SHELL" != "";
  inImpure = builtins ? currentSystem;
  inPure = !inImpure;

  # --- imports ---------------------------------------------------------------
  invoke = f: if isFunction f then f else import f;
}

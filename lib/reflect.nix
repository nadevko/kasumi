final: prev:
let
  inherit (final.reflect) inImpure getEnv;
in
prev.reflect or {} // {
  # --- purity state ----------------------------------------------------------
  inNixShell = getEnv "IN_NIX_SHELL" != "";
  inImpure = builtins ? currentSystem;
  inPure = !inImpure;
}

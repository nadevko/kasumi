final: prev:
let
  inherit (builtins) isAttrs;
  inherit (prev.attrsets) isDerivation;
  inherit (prev.trivial) id;

  inherit (final.meta) isSupportedDerivation;
  inherit (final.di) callWith callPackageBy;
  inherit (final.overlays) fuseLay foldLay;
  inherit (final.attrsets) mbindAttrs bindAttrs singletonPair;
in
rec {
  makeLayer =
    overlay: prev:
    let
      final = prev // self;
      extension = overlay final prev;

      self = extension // {
        inherit
          overlay
          final
          extension
          self
          ;

        call = callWith final;
        callPackage = callPackageBy self.call;
      };
    in
    self;

  fuseLayerWith = g: layer: makeLayer (fuseLay layer.overlay g) layer.final;
  foldLayerWith = gs: layer: makeLayer (foldLay ([ layer.overlay ] ++ gs)) layer.final;
  rebaseLayerTo = g: layer: makeLayer g layer.final;
  rebaseLayerToFold = gs: layer: makeLayer (foldLay gs) layer.final;

  collapseLayerWith =
    {
      include ? isDerivation,
      sep ? "-",
    }:
    layer:
    let
      makeRecurse =
        concat: n: v:
        if include v then
          singletonPair (concat n) v
        else if isAttrs v && v.recurseForDerivations or false then
          recurse (concat n) (v.extension or v)
        else
          [ ];

      recurse = prefix: bindAttrs <| makeRecurse (n: "${prefix}${sep}${n}");
    in
    mbindAttrs (makeRecurse id) (layer.extension or layer);

  collapseLayerSep = sep: collapseLayerWith { inherit sep; };
  collapseLayer = collapseLayerSep "-";

  collapseSupportedSep =
    sep: system:
    collapseLayerWith {
      include = isSupportedDerivation system;
      inherit sep;
    };
  collapseSupportedBy = collapseSupportedSep "-";
}

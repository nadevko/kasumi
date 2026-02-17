final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.lists) foldr;

  inherit (final.trivial) flip update;
  inherit (final.attrsets) pointwisel pointwiser;
  inherit (final.trivial) fix fix';
in
rec {
  makeLayMerge =
    merge: g: rattrs: final:
    let
      prev = rattrs final;
    in
    merge prev <| g final prev;

  makeLayRebaseWith =
    fix: merge: g: prev:
    fix (self: g (merge prev self) prev);

  makeLayRebase = makeLayRebaseWith fix;
  makeLayRebase' = makeLayRebaseWith fix';

  makeLayFuse =
    merge: g: h: final: prev:
    let
      mid = g final prev;
    in
    merge prev mid |> h final |> merge mid;

  makeLayFold = flip foldr (_: _: { });

  rebaseSelf = g: prev: fix (self: g self prev);
  rebaseSelf' = g: prev: fix' (self: g self prev);

  lay = makeLayMerge update;
  rebaseLay = makeLayRebase update;
  rebaseLay' = makeLayRebase' update;
  fuseLay = makeLayFuse update;
  foldLay = makeLayFold fuseLay;

  layr = makeLayMerge pointwiser;
  rebaseLayr = makeLayRebase pointwiser;
  rebaseLayr' = makeLayRebase' pointwiser;
  fuseLayr = makeLayFuse pointwiser;
  foldLayr = makeLayFold fuseLayr;

  layl = makeLayMerge pointwisel;
  rebaseLayl = makeLayRebase pointwisel;
  rebaseLayl' = makeLayRebase' pointwisel;
  fuseLayl = makeLayFuse pointwisel;
  foldLayl = makeLayFold fuseLayl;

  overlayr =
    g:
    if isFunction g then
      final: prev:
      let
        prev' = g prev;
      in
      if isFunction prev' then g final prev else prev'
    else
      _: _: g;

  overlayl =
    g:
    if isFunction g then
      final: prev:
      let
        final' = g final;
      in
      if isFunction final' then final' prev else final'
    else
      _: _: g;

  nestOverlayWith =
    merge: base: n: g: final: prev:
    let
      prevN = prev.${base} or { };
    in
    {
      ${n} = merge prevN <| g final.${n} prevN;
    };

  nestOverlay = nestOverlayWith update;
  nestOverlayr = nestOverlayWith pointwiser;
  nestOverlayl = nestOverlayWith pointwisel;
}

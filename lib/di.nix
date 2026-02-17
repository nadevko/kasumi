final: prev:
let
  inherit (builtins)
    attrNames
    functionArgs
    intersectAttrs
    filter
    head
    length
    concatStringsSep
    concatMap
    ;
  inherit (prev.lists)
    take
    sortOn
    init
    last
    findFirst
    ;
  inherit (prev.strings) levenshteinAtMost levenshtein;
  inherit (prev.customisation) makeOverridable;

  inherit (final.trivial) invoke compose;
  inherit (final.debug) attrPos;
in
rec {
  getAnnotation =
    f: if f ? __functor then f.__functionArgs or (functionArgs <| f.__functor f) else functionArgs f;

  setAnnotation = args: f: {
    __functor = _: f;
    __annotation = args;
  };

  inheritAnnotationFrom = compose setAnnotation getAnnotation;

  callWith =
    context: f: overrides:
    let
      callee = invoke f;
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs context // overrides;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null <| attrNames calleeArgs;
    in
    if missing == null then
      callee callAttrs
    else
      let
        suggestions =
          [
            overrides
            context
          ]
          |> concatMap attrNames
          |> filter (levenshteinAtMost 2 missing)
          |> sortOn (levenshtein missing)
          |> take 3;

        didYouMean =
          if suggestions == [ ] then
            ""
          else if length suggestions == 1 then
            ", did you mean '${head suggestions}'?"
          else
            ", did you mean '${concatStringsSep "', '" <| init suggestions}' or '${last suggestions}'?";

        pos = attrPos missing calleeArgs;
      in
      abort "kasumi.lib.di.callWith: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callPackageBy = call: f: invoke f |> call |> makeOverridable;
  callPackageWith = pkgs: callPackageBy <| callWith pkgs;
}

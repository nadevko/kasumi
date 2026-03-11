final: prev:
let
  inherit (import ./bitOp.nix)
    bitOp
    tableAnd
    tableOr
    tableXor
    ;
in
{
  # --- 2.1 -------------------------------------------------------------------
  bitAnd = prev.bitAnd or (bitOp tableAnd);
  bitOr = prev.bitOr or (bitOp tableOr);
  bitXor = prev.bitXor or (bitOp tableXor);
  # fromTOML = prev.fromTOML; !!! TODO
  concatMap = prev.concatMap or (f: xs: final.concatLists (final.map f xs));
  mapAttrs =
    prev.mapAttrs or (
      f: set:
      final.listToAttrs (
        final.map (name: {
          inherit name;
          value = f name set.${name};
        }) (final.attrNames set)
      )
    );

  # --- 2.3 -------------------------------------------------------------------
  isPath = prev.isPath or (x: final.typeOf x == "path");
  # hashFile = prev.hashFile; !!! TODO

  # --- 2.4 -------------------------------------------------------------------
  # fetchTree = prev.fetchTree; !!! TODO
  # getFlake = prev.getFlake; !!! TODO
  floor =
    prev.floor or (
      x:
      if final.isInt x then
        x
      else
        let
          str = toString x;
          m = final.match "(-?[0-9]+)(\\.[0-9]+|e.*)?" str;
          int = if m == null then 0 else final.fromJSON (final.head m);
          isLess = x < (final.fromJSON (final.head m));
        in
        if x >= 0 || !isLess then int else int - 1
    );
  ceil =
    prev.ceil or (
      x:
      if final.isInt x then
        x
      else
        let
          fl = final.floor x;
        in
        if x == fl then fl else fl + 1
    );

  # --- 2.5 -------------------------------------------------------------------
  groupBy =
    prev.groupBy or (
      f:
      final.foldl' (
        acc: x:
        let
          name = f x;
        in
        acc // { ${name} = (acc.${name} or [ ]) ++ [ x ]; }
      ) { }
    );

  # --- 2.6 -------------------------------------------------------------------
  zipAttrsWith =
    prev.zipAttrsWith or (
      if prev ? groupBy then
        f: sets:
        final.mapAttrs (name: values: f name (final.map (v: v.value) values)) (
          prev.groupBy (attr: attr.name) (
            final.concatMap (set: final.mapAttrsToList (name: value: { inherit name value; }) set) sets
          )
        )
      else
        f: sets:
        final.listToAttrs (
          final.map (name: {
            inherit name;
            value = f name (final.catAttrs name sets);
          }) (final.concatMap final.attrNames sets)
        )
    );

  # --- 2.8 -------------------------------------------------------------------
  fetchClosure =
    prev.fetchClosure or (
      args:
      let
        raw = if args ? toPath && args.toPath != "" then args.toPath else args.fromPath;
        str = final.toString raw;
        path = final.toPath str;
      in
      if final.pathExists path then
        final.storePath path
      else
        final.abort ''
           [1;31merror:[0m path '${path}' does not exist in the Nix store

          This polyfill only supports paths already present in the local store 
          (simulating final.storePath). To fetch from '${args.fromStore or "unknown cache"}',
          upgrade to Nix 2.8+ or ensure the closure is pre-loaded.
        ''
    );

  # --- 2.9 -------------------------------------------------------------------
  break = prev.break or (x: x);

  # --- 2.10 ------------------------------------------------------------------
  traceVerbose = prev.traceVerbose or (_: x: x);

  # --- 2.14 ------------------------------------------------------------------
  readFileType =
    prev.readFileType or (
      path:
      let
        str = final.toString path;
        base = final.baseNameOf str;
        dir = final.dirOf str;
        listing = final.readDir dir;
      in
      listing.${base} or (final.throw "path '${path}' does not exist")
    );

  # --- 2.18 ------------------------------------------------------------------
  # parseFlakeRef = prev.parseFlakeRef or (import ./parseFlakeRef.nix final); !!! TODO
  # flakeRefToString = prev.flakeRefToString or (import ./flakeRefToString.nix final); !!! TODO
  outputOf =
    prev.outputOf or (output: drv: if final.isAttrs drv && drv ? ${output} then drv.${output} else drv);

  # --- 2.19 ------------------------------------------------------------------
  # convertHash = prev.convertHash; !!! TODO

  # --- 2.23 ------------------------------------------------------------------
  warn =
    prev.warn or (
      msg: x:
      assert final.isString msg;
      if
        final.elem (final.getEnv "NIX_ABORT_ON_WARN") [
          "1"
          "true"
          "yes"
        ]
      then
        final.trace ("[1;31mevaluation warning:[0m " + msg) (
          final.abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors."
        )
      else
        final.trace ("[1;35mevaluation warning:[0m " + msg) (final.seq x x)
    );
}

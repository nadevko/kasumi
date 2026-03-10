final: prev:
let
  # --- bitAnd bitOr bitXor ---------------------------------------------------
  tableAnd = mkTable (a: b: if a == 1 && b == 1 then 1 else 0);
  tableOr = mkTable (a: b: if a == 1 || b == 1 then 1 else 0);
  tableXor = mkTable (a: b: if a != b then 1 else 0);

  range = final.genList (x: x) 16;
  mkTable = op: final.map (a: final.map (b: apply4 op a b) range) range;

  apply4 =
    op: a: b:
    let
      get =
        n: i:
        let
          # n % 2
          div =
            if i == 0 then
              1
            else if i == 1 then
              2
            else if i == 2 then
              4
            else
              8;
        in
        (n / div) - ((n / div) / 2 * 2);
      r0 = op (get a 0) (get b 0);
      r1 = op (get a 1) (get b 1);
      r2 = op (get a 2) (get b 2);
      r3 = op (get a 3) (get b 3);
    in
    r0 + r1 * 2 + r2 * 4 + r3 * 8;

  bitOp =
    table:
    let
      recurse =
        a: b:
        if a == 0 && b == 0 then
          0
        else
          let
            # n % 16
            a_p = a - (a / 16 * 16);
            b_p = b - (b / 16 * 16);
            res = final.elemAt (final.elemAt table a_p) b_p;
          in
          res + 16 * (recurse (a / 16) (b / 16));
    in
    a: b:
    assert a >= 0 && b >= 0;
    if a == b then a else recurse a b;

  # === api ===================================================================
  self = {
    # --- 2.1 -----------------------------------------------------------------
    bitAnd = prev.bitAnd or (bitOp tableAnd);
    bitOr = prev.bitOr or (bitOp tableOr);
    bitXor = prev.bitXor or (bitOp tableXor);
    fromTOML = prev.fromTOML;
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

    # --- 2.3 -----------------------------------------------------------------
    isPath = prev.isPath or (x: final.typeOf x == "path");
    hashFile = prev.hashFile;

    # --- 2.4 -----------------------------------------------------------------
    fetchTree = prev.fetchTree;
    getFlake = prev.getFlake;
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

    # --- 2.5 -----------------------------------------------------------------
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

    # --- 2.6 -----------------------------------------------------------------
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

    # --- 2.8 -----------------------------------------------------------------
    fetchClosure = prev.fetchClosure;

    # --- 2.9 -----------------------------------------------------------------
    break = prev.break or (x: x);

    # --- 2.10 ----------------------------------------------------------------
    traceVerbose = prev.traceVerbose or (_: x: x);

    # --- 2.14 ----------------------------------------------------------------
    readFileType =
      prev.readFileType or (
        path:
        let
          str = final.toString path;
          base = final.baseNameOf str;
          dir = final.dirOf str;
          listing = final.readDir dir;
        in
        listing.${base} or final.throw "[1;31merror:[0m path '${path}' does not exist"
      );

    # --- 2.18 ----------------------------------------------------------------
    parseFlakeRef = prev.parseFlakeRef;
    flakeRefToString = prev.flakeRefToString;
    outputOf =
      prev.outputOf or (output: drv: if final.isAttrs drv && drv ? ${output} then drv.${output} else drv);

    # --- 2.19 ----------------------------------------------------------------
    convertHash = prev.convertHash;

    # --- 2.23 ----------------------------------------------------------------
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
  };
in
prev // self

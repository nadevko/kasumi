{ lib }:
let
  inherit (lib)
    concatMapStringsSep
    isList
    isAttrs
    substring
    attrValues
    concatLists
    const
    elem
    foldl'
    generators
    id
    mapAttrs
    ;
in

rec {
  inherit (builtins) trace addErrorContext unsafeGetAttrPos;

  # -- TRACING --

  traceIf =
    pred: msg: x:
    if pred then trace msg x else x;

  traceValFn = f: x: trace (f x) x;

  traceVal = traceValFn id;

  traceSeq = x: y: trace (builtins.deepSeq x x) y;

  traceSeqN =
    depth: x: y:
    let
      snip =
        v:
        if isList v then
          noQuotes "[…]" v
        else if isAttrs v then
          noQuotes "{…}" v
        else
          v;
      noQuotes = str: v: {
        __pretty = const str;
        val = v;
      };
      modify =
        n: fn: v:
        if (n == 0) then
          fn v
        else if isList v then
          map (modify (n - 1) fn) v
        else if isAttrs v then
          mapAttrs (const (modify (n - 1) fn)) v
        else
          v;
    in
    trace (generators.toPretty { allowPrettyValues = true; } (modify depth snip x)) y;

  traceValSeqFn = f: v: traceValFn f (builtins.deepSeq v v);

  traceValSeq = traceValSeqFn id;

  traceValSeqNFn =
    f: depth: v:
    traceSeqN depth (f v) v;

  traceValSeqN = traceValSeqNFn id;

  traceFnSeqN =
    depth: name: f: v:
    let
      res = f v;
    in
    lib.traceSeqN (depth + 1) {
      fn = name;
      from = v;
      to = res;
    } res;

  # -- TESTING --

  runTests =
    tests:
    concatLists (
      attrValues (
        mapAttrs (
          name: test:
          let
            testsToRun = if tests ? tests then tests.tests else [ ];
          in
          if
            (substring 0 4 name == "test" || elem name testsToRun)
            && ((testsToRun == [ ]) || elem name tests.tests)
            && (test.expr != test.expected)

          then
            [
              {
                inherit name;
                expected = test.expected;
                result = test.expr;
              }
            ]
          else
            [ ]
        ) tests
      )
    );

  throwTestFailures =
    {
      failures,
      description ? "tests",
      ...
    }:
    if failures == [ ] then
      null
    else
      let
        toPretty =
          value:
          # Thanks to @Ma27 for this:
          #
          # > The `unsafeDiscardStringContext` is useful when the `toPretty`
          # > stumbles upon a derivation that would be realized without it (I
          # > ran into the problem when writing a test for a flake helper where
          # > I creating a bunch of "mock" derivations for different systems
          # > and Nix then tried to build those when the error-string got
          # > forced).
          #
          # See: https://github.com/NixOS/nixpkgs/pull/416207#discussion_r2145942389
          builtins.unsafeDiscardStringContext (generators.toPretty { allowPrettyValues = true; } value);

        failureToPretty = failure: ''
          FAIL ${toPretty failure.name}:
          Expected:
          ${toPretty failure.expected}

          Result:
          ${toPretty failure.result}
        '';

        traceFailures = foldl' (_accumulator: failure: traceVal (failureToPretty failure)) null failures;
      in
      throw (
        builtins.seq traceFailures (
          "${builtins.toString (builtins.length failures)} ${description} failed:\n- "
          + (concatMapStringsSep "\n- " (failure: failure.name) failures)
          + "\n\n"
          + builtins.toJSON failures
        )
      );

  testAllTrue = expr: {
    inherit expr;
    expected = map (x: true) expr;
  };
}

{ lib }:

let
  inherit (lib.trivial)
    isFunction
    isInt
    functionArgs
    pathExists
    release
    setFunctionArgs
    toBaseDigits
    version
    versionSuffix
    warn
    ;
  inherit (lib) isString;
in
{
  # Pull in some builtins not included elsewhere.
  inherit (builtins)
    pathExists
    readFile
    isBool
    isInt
    isFloat
    add
    sub
    mul
    div
    lessThan
    seq
    deepSeq
    genericClosure
    bitAnd
    bitOr
    bitXor
    ceil
    floor
    ;

  ## Simple (higher order) functions

  id = x: x;

  const = x: y: x;

  pipe = builtins.foldl' (x: f: f x);

  # note please don’t add a function like `compose = flip pipe`.
  # This would confuse users, because the order of the functions
  # in the list is not clear. With pipe, it’s obvious that it
  # goes first-to-last. With `compose`, not so much.

  ## Named versions corresponding to some builtin operators.

  concat = x: y: x ++ y;

  "or" = x: y: x || y;

  and = x: y: x && y;

  # We explicitly invert the arguments purely as a type assertion.
  # This is invariant under XOR, so it does not affect the result.
  xor = x: y: (!x) != (!y);

  bitNot = builtins.sub (-1);

  boolToString = b: if b then "true" else "false";

  boolToYesNo = b: if b then "yes" else "no";

  mergeAttrs = x: y: x // y;

  flip =
    f: a: b:
    f b a;

  defaultTo = default: maybeValue: if maybeValue != null then maybeValue else default;

  mapNullable = f: a: if a == null then a else f a;

  ## nixpkgs version strings

  version = release + versionSuffix;

  release = lib.strings.fileContents ./.version;

  oldestSupportedRelease =
    # Update on master only. Do not backport.
    2511;

  isInOldestRelease =
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2411)
      "lib.isInOldestRelease is deprecated. Use lib.oldestSupportedReleaseIsAtLeast instead."
      lib.oldestSupportedReleaseIsAtLeast;

  oldestSupportedReleaseIsAtLeast = release: release <= lib.trivial.oldestSupportedRelease;

  codeName = "Yarara";

  versionSuffix =
    let
      suffixFile = ../.version-suffix;
    in
    if pathExists suffixFile then lib.strings.fileContents suffixFile else "pre-git";

  revisionWithDefault =
    default:
    let
      revisionFile = "${toString ./..}/.git-revision";
      gitRepo = "${toString ./..}/.git";
    in
    if lib.pathIsGitRepo gitRepo then
      lib.commitIdFromGitRepo gitRepo
    else if lib.pathExists revisionFile then
      lib.fileContents revisionFile
    else
      default;

  nixpkgsVersion = warn "lib.nixpkgsVersion is a deprecated alias of lib.version." version;

  inNixShell = builtins.getEnv "IN_NIX_SHELL" != "";

  inPureEvalMode = !builtins ? currentSystem;

  ## Integer operations

  min = x: y: if x < y then x else y;

  max = x: y: if x > y then x else y;

  mod = base: int: base - (int * (builtins.div base int));

  ## Comparisons

  compare =
    a: b:
    if a < b then
      -1
    else if a > b then
      1
    else
      0;

  splitByAndCompare =
    p: yes: no: a: b:
    if p a then
      if p b then yes a b else -1
    else if p b then
      1
    else
      no a b;

  importJSON = path: builtins.fromJSON (builtins.readFile path);

  importTOML = path: fromTOML (builtins.readFile path);

  warn =
    # Since Nix 2.23, https://github.com/NixOS/nix/pull/10592
    builtins.warn or (
      let
        mustAbort = lib.elem (builtins.getEnv "NIX_ABORT_ON_WARN") [
          "1"
          "true"
          "yes"
        ];
      in
      # Do not eta reduce v, so that we have the same strictness as `builtins.warn`.
      msg: v:
      # `builtins.warn` requires a string message, so we enforce that in our implementation, so that callers aren't accidentally incompatible with newer Nix versions.
      assert isString msg;
      if mustAbort then
        builtins.trace "[1;31mevaluation warning:[0m ${msg}" (
          abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors."
        )
      else
        builtins.trace "[1;35mevaluation warning:[0m ${msg}" v
    );

  warnIf = cond: msg: if cond then warn msg else x: x;

  warnIfNot = cond: msg: if cond then x: x else warn msg;

  throwIfNot = cond: msg: if cond then x: x else throw msg;

  throwIf = cond: msg: if cond then throw msg else x: x;

  checkListOfEnum =
    msg: valid: given:
    let
      unexpected = lib.subtractLists valid given;
    in
    lib.throwIfNot (unexpected == [ ])
      "${msg}: ${builtins.concatStringsSep ", " (map toString unexpected)} unexpected; valid ones: ${builtins.concatStringsSep ", " (map toString valid)}";

  info = msg: builtins.trace "INFO: ${msg}";

  showWarnings = warnings: res: lib.foldr (w: x: warn w x) res warnings;

  ## Function annotations

  setFunctionArgs = f: args: {
    # TODO: Should we add call-time "type" checking like built in?
    __functor = self: f;
    __functionArgs = args;
  };

  functionArgs =
    f:
    if f ? __functor then
      f.__functionArgs or (functionArgs (f.__functor f))
    else
      builtins.functionArgs f;

  isFunction = f: builtins.isFunction f || (f ? __functor && isFunction (f.__functor f));

  mirrorFunctionArgs =
    f:
    let
      fArgs = functionArgs f;
    in
    g: setFunctionArgs g fArgs;

  toFunction = v: if isFunction v then v else k: v;

  fromHexString =
    str:
    let
      match = builtins.match "(0x)?([0-7]?[0-9A-Fa-f]{1,15})" str;
    in
    if match != null then
      (fromTOML "v=0x${builtins.elemAt match 1}").v
    else
      # TODO: Turn this into a `throw` in 26.05.
      assert lib.warn "fromHexString: ${
        lib.generators.toPretty { } str
      } is not a valid input and will be rejected in 26.05" true;
      let
        noPrefix = lib.strings.removePrefix "0x" (lib.strings.toLower str);
      in
      (fromTOML "v=0x${noPrefix}").v;

  toHexString =
    let
      hexDigits = {
        "10" = "A";
        "11" = "B";
        "12" = "C";
        "13" = "D";
        "14" = "E";
        "15" = "F";
      };
      toHexDigit = d: if d < 10 then toString d else hexDigits.${toString d};
    in
    i: lib.concatMapStrings toHexDigit (toBaseDigits 16 i);

  toBaseDigits =
    base: i:
    let
      go =
        i:
        if i < base then
          [ i ]
        else
          let
            r = i - ((i / base) * base);
            q = (i - r) / base;
          in
          [ r ] ++ go q;
    in
    assert (isInt base);
    assert (isInt i);
    assert (base >= 2);
    assert (i >= 0);
    lib.reverseList (go i);
}

final: prev:
let
  attrs = {
    inherit (builtins) mapAttrs;
    attr = builtins.hasAttr;
    collect = builtins.listToAttrs;
    get = builtins.getAttr;
    intersectR = builtins.intersectAttrs;
    names = builtins.attrNames;
    omit = removeAttrs;
    pluck = builtins.catAttrs;
    values = builtins.attrValues;
    zipWith = builtins.zipAttrsWith;
  };
  dag = {
    transitiveClosure = builtins.genericClosure;
  };
  debug = {
    inherit abort break throw;
    inherit (builtins)
      deepSeq
      seq
      trace
      warn
      ;
    deepTrace = builtins.traceVerbose;
    dump = builtins.toXML;
    explainFailure = builtins.addErrorContext;
  };
  deprecated = { inherit (builtins) toPath; };
  derivations = {
    inherit (builtins) getContext hasContext;
    inherit derivation placeholder;
    dependOn = builtins.appendContext;
    derivation' = derivationStrict;
    getOutput = builtins.outputOf;
    tryIgnoreDependency = builtins.unsafeDiscardOutputDependency;
    tryStripContext = builtins.unsafeDiscardStringContext;
    withOutputsOf = builtins.addDrvOutputDependencies;
  };
  fetchers = {
    inherit (builtins)
      fetchClosure
      fetchGit
      fetchMercurial
      fetchTarball
      fetchTree
      ;
    fetchUrl = builtins.fetchurl;
  };
  filesystem = {
    inherit (builtins) hashFile readDir readFile;
    exists = builtins.pathExists;
    findInNixPath = builtins.findFile;
    readType = builtins.readFileType;
    storeAs = builtins.toFile;
    storePath = builtins.storePath;
    storeWhere = builtins.filterSource;
    storeWith = builtins.path;
  };
  flakes =
    # use `let` as `flakey builtins not found` lsp workaround
    let
      inherit (builtins) flakeRefToString getFlake parseFlakeRef;
    in
    {
      fetchFlake = getFlake;
      fromRef = parseFlakeRef;
      toRef = flakeRefToString;
    };
  lists = {
    inherit map;
    inherit (builtins)
      all
      any
      concatLists
      concatMap
      elem
      filter
      groupBy
      head
      partition
      sort
      tail
      ;
    at = builtins.elemAt;
    foldL' = builtins.foldl';
    generate = builtins.genList;
    size = builtins.length;
  };
  numeric = {
    inherit (builtins)
      add
      bitAnd
      bitOr
      bitXor
      ceil
      div
      floor
      mul
      sub
      ;
    lt = builtins.lessThan;
  };
  meta = {
    inherit (builtins) compareVersions splitVersion;
    fromDrvName = builtins.parseDrvName;
  };
  paths = {
    basename = baseNameOf;
    dirname = dirOf;
    nixStorePath = builtins.storeDir;
  };
  prelude = {
    inherit
      false
      import
      isNull
      null
      true
      ;
    inherit (builtins)
      isAttrs
      isBool
      isFloat
      isFunction
      isInt
      isList
      isPath
      typeOf
      ;
    builtins = relude;
    importWith = scopedImport;
    isStr = builtins.isString;
  };
  reflect = {
    inherit (builtins)
      currentSystem
      currentTime
      functionArgs
      getEnv
      langVersion
      nixPath
      nixVersion
      tryEval
      ;
    tryGetAttrPos = builtins.unsafeGetAttrPos;
  };
  strings = {
    inherit (builtins) convertHash match split;
    fromJson = builtins.fromJSON;
    fromToml = fromTOML;
    hashWith = builtins.hashString;
    joinSep = builtins.concatStringsSep;
    length = builtins.stringLength;
    replaceAll = builtins.replaceStrings;
    slice = builtins.substring;
    toJson = builtins.toJSON;
    toStr = toString;
  };

  _deprecationWarn =
    n:
    debug.warn ''
      `kasumi.lib.${n}` has been moved to `kasumi.lib.deprecated.${n}`.

      It is still available there for compatibility, but its use is discouraged
      and it may be removed in the future.
    '';

  relude =
    attrs.mapAttrs _deprecationWarn deprecated
    // attrs
    // dag
    // debug
    // derivations
    // fetchers
    // filesystem
    // flakes
    // lists
    // meta
    // numeric
    // paths
    // prelude
    // reflect
    // strings;
in
{
  inherit
    attrs
    dag
    debug
    deprecated
    derivations
    fetchers
    filesystem
    flakes
    lists
    meta
    numeric
    paths
    prelude
    reflect
    strings
    ;
  inherit _deprecationWarn;
}
// relude

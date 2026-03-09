final: prev:
let
  attrs = {
    inherit (builtins) mapAttrs;
    attr = builtins.hasAttr;
    fromPairs = builtins.listToAttrs;
    get = builtins.getAttr;
    intersectR = builtins.intersectAttrs;
    names = builtins.attrNames;
    omit = removeAttrs;
    pluck = builtins.catAttrs;
    values = builtins.attrValues;
    zipWith = builtins.zipAttrsWith;
  };
  debug = {
    inherit abort break throw;
    inherit (builtins)
      deepSeq
      functionArgs
      seq
      tryEval
      warn
      ;
    dump = builtins.toXML;
    explainFailure = builtins.addErrorContext;
    log = builtins.trace;
    trace = builtins.traceVerbose;
    tryGetAttrPos = builtins.unsafeGetAttrPos;
  };
  deprecated = { inherit (builtins) toPath; };
  derivations = {
    inherit (builtins) getContext hasContext parseDrvName;
    inherit derivation placeholder;
    dependOn = builtins.appendContext;
    derivation' = derivationStrict;
    getOutput = builtins.outputOf;
    transitiveClosure = builtins.genericClosure;
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
    inherit (builtins)
      hashFile
      pathExists
      readDir
      readFile
      ;
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
      parseRef = parseFlakeRef;
      showRef = flakeRefToString;
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
    fold' = builtins.foldl';
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
  paths = {
    basename = baseNameOf;
    dirname = dirOf;
    nixStorePath = builtins.storeDir;
  };
  runtime = {
    inherit import;
    inherit (builtins)
      currentSystem
      currentTime
      getEnv
      langVersion
      nixPath
      nixVersion
      ;
    importWith = scopedImport;
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
  types = {
    inherit
      false
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
    isStr = builtins.isString;
  };
  versions = { inherit (builtins) compareVersions splitVersion; };

  __deprecationWarn =
    n:
    builtins.warn ''
      `kasumi.lib.${n}` has been moved to `kasumi.lib.deprecated.${n}`.

      It is still available there for compatibility, but its use is discouraged
      and it may be removed in the future.
    '';
in
{
  inherit
    attrs
    debug
    deprecated
    derivations
    fetchers
    filesystem
    flakes
    lists
    numeric
    paths
    runtime
    strings
    types
    versions
    ;
  inherit __deprecationWarn;
}
// attrs
// debug
// builtins.mapAttrs __deprecationWarn deprecated
// derivations
// fetchers
// filesystem
// flakes
// lists
// numeric
// paths
// runtime
// strings
// types
// versions

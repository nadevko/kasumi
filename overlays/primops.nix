final: prev:
let
  attrs = {
    inherit (prev) mapAttrs;
    attr = prev.hasAttr;
    collect = prev.listToAttrs;
    get = prev.getAttr;
    intersectR = prev.intersectAttrs;
    names = prev.attrNames;
    omit = prev.removeAttrs;
    pluck = prev.catAttrs;
    values = prev.attrValues;
    zipWith = prev.zipAttrsWith;
  };
  dag = {
    transitiveClosure = prev.genericClosure;
  };
  debug = {
    inherit (prev)
      abort
      break
      deepSeq
      seq
      throw
      trace
      warn
      ;
    deepTrace = prev.traceVerbose;
    dump = prev.toXML;
    explainFailure = prev.addErrorContext;
  };
  deprecated = { inherit (prev) toPath; };
  derivations = {
    inherit (prev)
      derivation
      getContext
      hasContext
      placeholder
      ;
    dependOn = prev.appendContext;
    derivation' = prev.derivationStrict;
    getOutput = prev.outputOf;
    tryIgnoreDependency = prev.unsafeDiscardOutputDependency;
    tryStripContext = prev.unsafeDiscardStringContext;
    withOutputsOf = prev.addDrvOutputDependencies;
  };
  fetchers = {
    inherit (prev)
      fetchClosure
      fetchGit
      fetchMercurial
      fetchTarball
      fetchTree
      ;
    fetchUrl = prev.fetchurl;
  };
  filesystem = {
    inherit (prev) hashFile readDir readFile;
    exists = prev.pathExists;
    findInNixPath = prev.findFile;
    readType = prev.readFileType;
    storeAs = prev.toFile;
    storePath = prev.storePath;
    storeWhere = prev.filterSource;
    storeWith = prev.path;
  };
  flakes = {
    fetchFlake = prev.getFlake;
    fromRef = prev.parseFlakeRef;
    toRef = prev.flakeRefToString;
  };
  lists = {
    inherit (prev)
      all
      any
      concatLists
      concatMap
      elem
      filter
      groupBy
      head
      map
      partition
      sort
      tail
      ;
    at = prev.elemAt;
    foldL' = prev.foldl';
    generate = prev.genList;
    size = prev.length;
  };
  numeric = {
    inherit (prev)
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
    lt = prev.lessThan;
  };
  meta = {
    inherit (prev) compareVersions splitVersion;
    fromDrvName = prev.parseDrvName;
  };
  paths = {
    basename = prev.baseNameOf;
    dirname = prev.dirOf;
    nixStorePath = prev.storeDir;
  };
  prelude = {
    inherit primops;
    inherit (prev)
      false
      import
      isAttrs
      isBool
      isFloat
      isFunction
      isInt
      isList
      isNull
      isPath
      isString
      null
      true
      typeOf
      ;
    importWith = scopedImport;
  };
  reflect = {
    inherit (prev)
      currentSystem
      currentTime
      functionArgs
      getEnv
      langVersion
      nixPath
      nixVersion
      tryEval
      ;
    tryGetAttrPos = prev.unsafeGetAttrPos;
  };
  strings = {
    inherit (prev) convertHash match split;
    fromJson = prev.fromJSON;
    fromToml = fromTOML;
    hashWith = prev.hashString;
    joinSep = prev.concatStringsSep;
    length = prev.stringLength;
    replaceAll = prev.replaceStrings;
    slice = prev.substring;
    toJson = prev.toJSON;
    toStr = prev.toString;
  };

  _deprecationWarn =
    n:
    debug.warn ''
      `${n}` has been moved to `deprecated.${n}`.

      It is still available there for compatibility, but its use is discouraged
      and it may be removed in the future.
    '';

  primops =
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
// primops

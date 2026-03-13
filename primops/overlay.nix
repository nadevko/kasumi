final: prev:
let
  attrs = {
    inherit (prev) mapAttrs;
    attr' = prev.hasAttr;
    get' = prev.getAttr;
    intersectR = prev.intersectAttrs;
    names = prev.attrNames;
    ofPairs = prev.listToAttrs;
    omit = names: set: prev.removeAttrs set names;
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
  derivations = {
    inherit (prev)
      derivation
      getContext
      hasContext
      placeholder
      ;
    dependOn = prev.appendContext;
    derivation' = prev.derivationStrict;
    getOutput = name: drv: prev.outputOf drv name;
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
      filter
      groupBy
      map
      partition
      ;
    at' = i: xs: prev.elemAt xs i;
    elem = xs: x: prev.elem x xs;
    foldL' = prev.foldl';
    generate = prev.genList;
    head' = prev.head;
    size = prev.length;
    sortBy = prev.sort;
    tail' = prev.tail;
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
    inherit (prev) toPath;
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
    importWith = prev.scopedImport;
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
    inherit (prev)
      convertHash
      hashString
      match
      split
      ;
    fromJson = prev.fromJSON;
    fromToml = prev.fromTOML;
    joinSep = prev.concatStringsSep;
    length = prev.stringLength;
    replaceAll = prev.replaceStrings;
    slice = prev.substring;
    toJson = prev.toJSON;
    toStr = prev.toString;
  };

  primops =
    attrs
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
}
// primops

final: prev:
let
  attrs = {
    attr = prev.hasAttr;
    get = prev.getAttr;
    intersectR = prev.intersectAttrs;
    mapValues = prev.mapAttrs;
    names = prev.attrNames;
    ofPairs = prev.listToAttrs;
    omit = names: set: prev.removeAttrs set names;
    pluck = prev.catAttrs;
    values = prev.attrValues;
    zipBy = prev.zipAttrsWith;
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
    _shallowContext = prev.unsafeDiscardOutputDependency;
    _stripContext = prev.unsafeDiscardStringContext;
    inherit (prev)
      derivation
      getContext
      hasContext
      placeholder
      ;
    derivation' = prev.derivationStrict;
    getOutput = name: drv: prev.outputOf drv name;
    withContext = prev.appendContext;
    withDeepContext = prev.addDrvOutputDependencies;
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
    inherit (prev)
      hashFile
      readDir
      readFile
      storePath
      ;
    exists = prev.pathExists;
    findInNixPath = prev.findFile;
    readType = prev.readFileType;
    storeAs = prev.toFile;
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
      groupBy
      head
      map
      partition
      tail
      ;
    at = i: xs: prev.elemAt xs i;
    elem = xs: x: prev.elem x xs;
    foldL' = prev.foldl';
    generate = prev.genList;
    size = prev.length;
    sortBy = prev.sort;
    where = prev.filter;
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
    _getAttrPos = prev.unsafeGetAttrPos;
    inherit (prev)
      currentSystem
      currentTime
      functionArgs
      getEnv
      langVersion
      nixPath
      nixVersion
      ;
    try = prev.tryEval;
  };
  strings = {
    inherit (prev)
      convertHash
      hashString
      match
      split
      toString
      ;
    fromJson = prev.fromJSON;
    fromToml = prev.fromTOML;
    joinSep = prev.concatStringsSep;
    length = prev.stringLength;
    replaceAll = prev.replaceStrings;
    substr = prev.substring;
    toJson = prev.toJSON;
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

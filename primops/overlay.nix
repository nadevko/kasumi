final: prev:
let
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
    annotateError = prev.addErrorContext;
    deepTrace = prev.traceVerbose;
    dump = prev.toXML;
  };
  derivations = {
    _stripContext = prev.unsafeDiscardStringContext;
    _stripDeepContext = prev.unsafeDiscardOutputDependency;
    inherit (prev) derivation hasContext placeholder;
    contextOf = prev.getContext;
    derivation' = prev.derivationStrict;
    getOutput = name: drv: prev.outputOf drv name;
    requireStorePath = prev.storePath;
    withContext = prev.appendContext;
    withDeepContext = prev.addDrvOutputDependencies;
  };
  fetchers = {
    inherit (prev) fetchGit fetchMercurial fetchTarball;
    fetchRef = prev.fetchTree;
    fetchStore = prev.fetchClosure;
    fetchUrl = prev.fetchurl;
  };
  filesystem = {
    inherit (prev) hashFile readDir readFile;
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
      concatMap
      head
      map
      partition
      tail
      ;
    at = i: xs: prev.elemAt xs i;
    concatAll = prev.concatLists;
    elem = xs: x: prev.elem x xs;
    foldLeft' = prev.foldl';
    generate = prev.genList;
    pluck = prev.catAttrs;
    size = prev.length;
    sortBy = prev.sort;
    where = prev.filter;
  };
  numeric = {
    inherit (prev)
      add
      ceil
      div
      floor
      mul
      sub
      ;
    band = prev.bitAnd;
    bor = prev.bitOr;
    bxor = prev.bitXor;
    lt = prev.lessThan;
  };
  meta = {
    inherit (prev) compareVersions splitVersion;
    fromDrvName = prev.parseDrvName;
  };
  paths = {
    inherit (prev) toPath;
    basenameOf = prev.baseNameOf;
    dirnameOf = prev.dirOf;
    nixStorePath = prev.storeDir;
  };
  prelude = {
    inherit primops;
    inherit (prev)
      false
      import
      isBool
      isFloat
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
    isLambda = prev.isFunction;
    isSet = prev.isAttrs;
  };
  reflect = {
    _getAttrPos = prev.unsafeGetAttrPos;
    inherit (prev)
      currentSystem
      currentTime
      getEnv
      langVersion
      nixPath
      nixVersion
      ;
    lambdaArgsOf = prev.functionArgs;
    try = prev.tryEval;
  };
  sets = {
    attr = prev.hasAttr;
    get = prev.getAttr;
    groupMap = prev.zipAttrsWith;
    groupWhere = prev.groupBy;
    intersectRight = prev.intersectAttrs;
    mapValues = prev.mapAttrs;
    namesOf = prev.attrNames;
    ofPairs = prev.listToAttrs;
    omit = names: set: prev.removeAttrs set names;
    valuesOf = prev.attrValues;
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

  primops = {
    inherit primops;
  }
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
  // sets
  // strings;

  lib = {
    lib = final;
    inherit
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
      sets
      strings
      ;
  }
  // primops;
in
lib

final: prev:
let
  self = {
    abort = prev.abort;
    add = prev.add;
    addDrvOutputDependencies = prev.addDrvOutputDependencies;
    addErrorContext = prev.addErrorContext;
    all = prev.all;
    any = prev.any;
    appendContext = prev.appendContext;
    attrNames = prev.attrNames;
    attrValues = prev.attrValues;
    baseNameOf = prev.baseNameOf;
    bitAnd = prev.bitAnd;
    bitOr = prev.bitOr;
    bitXor = prev.bitXor;
    break = prev.break;
    builtins = self;
    catAttrs = prev.catAttrs;
    ceil = prev.ceil;
    compareVersions = prev.compareVersions;
    concatLists = prev.concatLists;
    concatMap = prev.concatMap;
    concatStringsSep = prev.concatStringsSep;
    convertHash = prev.convertHash;
    currentSystem = prev.currentSystem;
    currentTime = prev.currentTime;
    deepSeq = prev.deepSeq;
    derivation = prev.derivation;
    derivationStrict = prev.derivationStrict;
    dirOf = prev.dirOf;
    div = prev.div;
    elem = prev.elem;
    elemAt = prev.elemAt;
    false = prev.false;
    fetchClosure = prev.fetchClosure;
    fetchGit = prev.fetchGit;
    fetchMercurial = prev.fetchMercurial;
    fetchTarball = prev.fetchTarball;
    fetchTree = prev.fetchTree;
    fetchurl = prev.fetchurl;
    filter = prev.filter;
    filterSource = prev.filterSource;
    findFile = prev.findFile;
    flakeRefToString = prev.flakeRefToString;
    floor = prev.floor;
    foldl' = prev.foldl';
    fromJSON = prev.fromJSON;
    fromTOML = prev.fromTOML;
    functionArgs = prev.functionArgs;
    genList = prev.genList;
    genericClosure = prev.genericClosure;
    getAttr = prev.getAttr;
    getContext = prev.getContext;
    getEnv = prev.getEnv;
    getFlake = prev.getFlake;
    groupBy = prev.groupBy;
    hasAttr = prev.hasAttr;
    hasContext = prev.hasContext;
    hashFile = prev.hashFile;
    hashString = prev.hashString;
    head = prev.head;
    import = prev.import;
    intersectAttrs = prev.intersectAttrs;
    isAttrs = prev.isAttrs;
    isBool = prev.isBool;
    isFloat = prev.isFloat;
    isFunction = prev.isFunction;
    isInt = prev.isInt;
    isList = prev.isList;
    isNull = prev.isNull;
    isPath = prev.isPath;
    isString = prev.isString;
    langVersion = prev.langVersion;
    length = prev.length;
    lessThan = prev.lessThan;
    listToAttrs = prev.listToAttrs;
    map = prev.map;
    mapAttrs = prev.mapAttrs;
    match = prev.match;
    mul = prev.mul;
    nixPath = prev.nixPath;
    nixVersion = prev.nixVersion;
    null = prev.null;
    outputOf = prev.outputOf;
    parseDrvName = prev.parseDrvName;
    parseFlakeRef = prev.parseFlakeRef;
    partition = prev.partition;
    path = prev.path;
    pathExists = prev.pathExists;
    placeholder = prev.placeholder;
    readDir = prev.readDir;
    readFile = prev.readFile;
    readFileType = prev.readFileType;
    removeAttrs = prev.removeAttrs;
    replaceStrings = prev.replaceStrings;
    scopedImport = prev.scopedImport;
    seq = prev.seq;
    sort = prev.sort;
    split = prev.split;
    splitVersion = prev.splitVersion;
    storeDir = prev.storeDir;
    storePath = prev.storePath;
    stringLength = prev.stringLength;
    sub = prev.sub;
    substring = prev.substring;
    tail = prev.tail;
    throw = prev.throw;
    toFile = prev.toFile;
    toJSON = prev.toJSON;
    toPath = prev.toPath;
    toString = prev.toString;
    toXML = prev.toXML;
    trace = prev.trace;
    traceVerbose = prev.traceVerbose;
    true = prev.true;
    tryEval = prev.tryEval;
    typeOf = prev.typeOf;
    unsafeDiscardOutputDependency = prev.unsafeDiscardOutputDependency;
    unsafeDiscardStringContext = prev.unsafeDiscardStringContext;
    unsafeGetAttrPos = prev.unsafeGetAttrPos;
    warn =
      prev.warn or (
        msg: x:
        assert prev.isString msg;
        if
          prev.elem (prev.getEnv "NIX_ABORT_ON_WARN") [
            "1"
            "true"
            "yes"
          ]
        then
          prev.trace ("[1;31mevaluation warning:[0m " + msg)
          <| abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors."
        else
          prev.trace ("[1;35mevaluation warning:[0m " + msg) x
      );
    zipAttrsWith = prev.zipAttrsWith;
  };
in
self

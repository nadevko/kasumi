final: prev:
let
  dag = { transitiveClosure = prev.genericClosure; };

  debug =
    { inherit (prev)
        abort
        break
        deepSeq
        seq
        throw
        trace
        warn
    ; deepTrace = prev.traceVerbose
    ; dump = prev.toXML
    ; explainError = prev.addErrorContext
    ; } ;

  derivations =
    { inherit (prev) derivation hasContext placeholder
    ; _stripContext = prev.unsafeDiscardStringContext
    ; _stripDeepContext = prev.unsafeDiscardOutputDependency
    ; contextOf = prev.getContext
    ; derivation' = prev.derivationStrict
    ; getOutput = name: drv: prev.outputOf drv name
    ; requireStorePath = prev.storePath
    ; withContext = prev.appendContext
    ; withDeepContext = prev.addDrvOutputDependencies
    ; } ;

  fetchers =
    { inherit (prev) fetchGit fetchMercurial fetchTarball
    ; fetchStore = prev.fetchClosure
    ; fetchUrl = prev.fetchurl
    ; fetchWith = prev.fetchTree
    ; } ;

  filesystem =
    { inherit (prev) hashFile readDir readFile
    ; exists = prev.pathExists
    ; findInNixPath = prev.findFile
    ; readType = prev.readFileType
    ; storeAs = prev.toFile
    ; storeWhere = prev.filterSource
    ; storeWith = prev.path
    ; } ;

  flakes =
    { importFlake = prev.getFlake
    ; fromRef = prev.parseFlakeRef
    ; toRef = prev.flakeRefToString
    ; } ;

  lists =
    { inherit (prev)
        all
        any
        concatMap
        foldl'
        map
        partition
    ; at = i: xs: prev.elemAt xs i
    ; concatAll = prev.concatLists
    ; contains = xs: x: prev.elem x xs
    ; generate = prev.genList
    ; headOf = prev.head
    ; pluck = prev.catAttrs
    ; sizeOf = prev.length
    ; sortBy = prev.sort
    ; tailOf = prev.tail
    ; where = prev.filter
    ; } ;

  numeric =
    { inherit (prev)
        add
        ceil
        div
        floor
        mul
        sub
    ; band = prev.bitAnd
    ; bor = prev.bitOr
    ; bxor = prev.bitXor
    ; lt = prev.lessThan
    ; } ;

  meta =
    { inherit (prev) compareVersions splitVersion
    ; fromDrvName = prev.parseDrvName
    ; } ;

  paths =
    { inherit (prev) toPath
    ; basenameOf = prev.baseNameOf
    ; dirnameOf = prev.dirOf
    ; nixStorePath = prev.storeDir
    ; } ;

  prelude =
    { inherit (prev)
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
    ; importWith = prev.scopedImport
    ; isLambda = prev.isFunction
    ; isSet = prev.isAttrs
    ; } ;

  reflect =
    { inherit (prev)
        currentSystem
        currentTime
        getEnv
        langVersion
        nixPath
        nixVersion
    ; _attrPosOf = prev.unsafeGetAttrPos
    ; getLambdaArgs = prev.functionArgs
    ; try = prev.tryEval
    ; } ;

  sets =
    { get = prev.getAttr
    ; groupMap = prev.zipAttrsWith
    ; groupWhere = prev.groupBy
    ; has = prev.hasAttr
    ; intersectr = prev.intersectAttrs
    ; mapValues = prev.mapAttrs
    ; namesOf = prev.attrNames
    ; ofPairs = prev.listToAttrs
    ; omit = names: set: prev.removeAttrs set names
    ; valuesOf = prev.attrValues
    ; } ;

  strings =
    { inherit (prev)
        convertHash
        hashString
        toString
    ; fromJson = prev.fromJSON
    ; fromToml = prev.fromTOML
    ; joinSep = prev.concatStringsSep
    ; lengthOf = prev.stringLength
    ; matches = prev.match
    ; replaceAll = prev.replaceStrings
    ; splits = prev.split
    ; substr = prev.substring
    ; toJson = prev.toJSON
    ; } ;

  primops =
    { inherit primops; }
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
    // strings
    ;

  lib =
    { inherit
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
    ; lib = final
    ; }
    // primops
    ;
in
lib

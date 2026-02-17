final: prev: {
  attrsets = import ../lib/attrsets.nix final prev;
  debug = import ../lib/debug.nix final prev;
  derivations = import ../lib/derivations.nix final prev;
  di = import ../lib/di.nix final prev;
  filesystem = import ../lib/filesystem.nix final prev;
  flakes = import ../lib/flakes.nix final prev;
  layers = import ../lib/layers.nix final prev;
  lib = import ../lib/lib.nix final prev;
  lists = import ../lib/lists.nix final prev;
  maintainers = import ../lib/maintainers.nix final prev;
  nixos = import ../lib/nixos.nix final prev;
  numerics = import ../lib/numerics.nix final prev;
  overlays = import ../lib/overlays.nix final prev;
  paths = import ../lib/paths.nix final prev;
  trivial = import ../lib/trivial.nix final prev;

  inherit (final.attrsets)
    attr
    singletonAttr
    pair
    singletonPair
    bindAttrs
    mbindAttrs
    mergeMapAttrs
    intersectWith
    partitionAttrs
    pointwisel
    pointwiser
    transposeAttrs
    genAttrsBy
    genTransposedAttrsBy
    genTransposedAttrs
    foldPathWith
    foldPath
    ;

  inherit (final.debug)
    warnIf
    throwIf
    warnIfNot
    throwIfNot
    validateEnumList
    info
    withWarns
    attrPos'
    attrPos
    ;

  inherit (final.di)
    getAnnotation
    setAnnotation
    inheritAnnotationFrom
    callWith
    callPackageBy
    callPackageWith
    ;

  inherit (final.filesystem)
    readDirPaths
    makeReadDirWrapper
    bindDir
    mbindDir
    mapDir
    mergeMapDir
    collectFiles
    collectNixFiles
    collapseDir
    collapseNixDirSep
    collapseNixDir
    readShards
    collapseShardsWith
    collapseShardsUntil
    readDirWithManifest
    readConfigurations
    readNixosConfigurations
    readTemplates
    readLibOverlay
    byNameOverlayWithName
    byNameOverlayFrom
    byNameOverlayWithPinsFrom
    comfyByNameOverlayFrom
    ;

  inherit (final.flakes)
    flakeSystems
    importFlakePkgs
    forAllSystems
    forSystems
    forAllPkgs
    forPkgs
    importPkgsForAll
    importPkgsFor
    ;

  inherit (final.layers)
    makeLayer
    fuseLayerWith
    foldLayerWith
    rebaseLayerTo
    rebaseLayerToFold
    collapseLayerWith
    collapseLayerSep
    collapseLayer
    collapseSupportedSep
    collapseSupportedBy
    ;

  inherit (final.lib)
    genLibAliasesPred
    genLibAliasesWithout
    genLibAliases
    forkLibAs
    forkLib
    augmentLibAs
    augmentLib
    ;

  inherit (final.lists)
    splitAt
    intersectStrings
    subtractStrings
    dfold
    ;

  inherit (final.derivations) isDerivation isSupportedDerivation;

  inherit (final.numerics)
    encodeIntWith
    fromHex
    toHex
    toBaseDigits
    ;

  inherit (final.overlays)
    makeLayMerge
    makeLayRebaseWith
    makeLayRebase
    makeLayRebase'
    makeLayFuse
    makeLayFold
    rebaseSelf
    rebaseSelf'
    lay
    rebaseLay
    rebaseLay'
    fuseLay
    foldLay
    layr
    rebaseLayr
    rebaseLayr'
    fuseLayr
    foldLayr
    layl
    rebaseLayl
    rebaseLayl'
    fuseLayl
    foldLayl
    overlayr
    overlayl
    nestOverlayWith
    nestOverlay
    nestOverlayr
    nestOverlayl
    ;

  inherit (final.paths)
    stemOf
    stemOfNix
    isDir
    isNix
    isHidden
    isVisible
    isVisibleNix
    isVisibleDir
    ;

  inherit (final.trivial)
    id
    const
    snd
    apply
    fapply
    concat
    update
    flip
    compose
    pipe
    fpipe
    eq
    neq
    boolNot
    boolOr
    boolAnd
    boolXor
    boolImply
    gt
    le
    ge
    min
    max
    mod
    bitNot
    boolToWith
    boolToTrue
    boolToYes
    ifElse
    withDefault
    applyNullable
    invoke
    importJSON
    importTOML
    isAppliable
    isFunctor
    toFunction
    toFunctor
    fix
    fix'
    isNixShellImpure
    isImpure
    isPure
    ;
}

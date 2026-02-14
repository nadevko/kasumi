final: prev:
let
  inherit (builtins) readDir pathExists mapAttrs;

  inherit (prev.trivial) const;
  inherit (prev) nixosSystem;

  inherit (final.attrsets)
    singletonPair
    bindAttrs
    mbindAttrs
    mergeMapAttrs
    attr
    ;
  inherit (final.paths)
    stemOfNix
    stemOf
    isVisibleNix
    isNix
    isHidden
    isVisibleDir
    isDir
    ;
  inherit (final.di) callPackageWith callPackageBy callWith;
in
rec {
  readDirPaths = root: mapAttrs (n: _: root + "/${n}") <| readDir root;

  makeReadDirWrapper =
    merge: f: root:
    merge (n: f (root + "/${n}") n) <| readDir root;

  bindDir = makeReadDirWrapper bindAttrs;
  mbindDir = makeReadDirWrapper mbindAttrs;

  mapDir = makeReadDirWrapper mapAttrs;
  mergeMapDir = makeReadDirWrapper mergeMapAttrs;

  collectFiles =
    {
      recurseInto ? _: isDir,
      include ? _: _: true,
      mapAttr ?
        abs: _: _:
        abs,
    }:
    let
      recurse = bindDir (
        abs: n: type:
        (if include n type then [ (mapAttr abs n type) ] else [ ])
        ++ (if recurseInto n type then recurse abs else [ ])
      );
    in
    recurse;

  collectNixFiles = collectFiles {
    recurseInto = isVisibleDir;
    include = isVisibleNix;
  };

  collapseDir =
    {
      recurseInto ? _: isDir,
      include ? _: type: !isDir type,

      concatPrefix ?
        prefix: n: _:
        "${prefix}-${n}",
      concatName ?
        prefix: n: _:
        "${prefix}-${stemOf n}",

      toRootPrefix ? n: _: n,
      toRootName ? n: _: stemOf n,
    }:
    let
      makeRecurse =
        toPrefix: toName: abs: n: type:
        let
          entry = singletonPair (toName n type) abs;
          subtree = recurse (toPrefix n type) abs;
        in
        (if include n type then entry else [ ]) ++ (if recurseInto n type then subtree else [ ]);
      recurse = prefix: bindDir <| makeRecurse (concatPrefix prefix) <| concatName prefix;
    in
    mbindDir <| makeRecurse toRootPrefix toRootName;

  collapseNixDirSep =
    sep:
    collapseDir {
      include = isVisibleNix;
      recurseInto = isVisibleDir;
      toRootPrefix = const;
      toRootName = n: _: stemOfNix n;
      concatPrefix =
        prefix: n: _:
        "${prefix}${sep}${n}";
      concatName =
        prefix: n: _:
        if n == "default.nix" then prefix else "${prefix}${sep}${stemOfNix n}";
    };

  collapseNixDir = collapseNixDirSep "-";

  readShards = mergeMapDir (
    abs: _: _:
    mapAttrs (n: _: abs + "/${n}") <| readDir abs
  );

  collapseShardsWith =
    {
      recurseInto ? _: isDir,
      include ? _: type: !isDir type,
    }@args:
    depth:
    mergeMapDir (
      abs: n: type:
      (if include n type then attr n abs else { })
      // (if 0 < depth && recurseInto n type then collapseShardsWith args (depth - 1) abs else { })
    );

  collapseShardsUntil = collapseShardsWith { };

  readDirWithManifest =
    f: root:
    let
      dir = readDir root;
    in
    mbindAttrs (
      n: type:
      let
        abs = root + "/${n}";
        config = if dir ? ${n + ".nix"} then import <| abs + ".nix" else { };
      in
      if isDir type -> isHidden n then [ ] else singletonPair n <| f abs n config
    ) dir;

  readConfigurations =
    builder: base: getter:
    readDirWithManifest (
      abs: n: config:
      let
        overrides = getter n;
      in
      builder (
        base
        // config
        // overrides
        // {
          modules =
            (collectNixFiles abs)
            ++ (base.modules or [ ])
            ++ (config.modules or [ ])
            ++ (overrides.modules or [ ]);
        }
      )
    );

  readNixosConfigurations = readConfigurations nixosSystem;

  readTemplates =
    descriptions:
    readDirWithManifest (
      abs: n: config:
      config
      // {
        path = abs;
        ${if descriptions ? ${n} then "description" else null} = descriptions.${n};
      }
    );

  readLibOverlay =
    root: final: prev:
    mbindDir (
      abs: n: type:
      if isHidden n then
        [ ]
      else if isDir type then
        let
          default = abs + "/default.nix";
        in
        if pathExists default then singletonPair n <| import default final prev else [ ]
      else if n != "default.nix" && isNix n then
        singletonPair (stemOfNix n) <| import abs final prev
      else
        [ ]
    ) root;

  byNameOverlayWithName =
    name: paths: final: _:
    let
      callPackage = final.callPackage or (callPackageWith final);
      suffix = "/" + name;
    in
    mapAttrs (_: abs: callPackage (abs + suffix) { }) paths;

  byNameOverlayFrom = byNameOverlayWithName "package.nix";

  byNameOverlayWithPinsFrom =
    paths: final: _:
    let
      call = final.call or (callWith final);
      callPackage = final.callPackage or (callPackageBy call);
    in
    mapAttrs (
      _: abs:
      let
        pins = abs + "/pins.nix";
      in
      callPackage (abs + "/package.nix") (if pathExists pins then call pins { } else { })
    ) paths;

  comfyByNameOverlayFrom =
    paths: final: prev:
    let
      call = final.call or (callWith final);
      callPackage = final.callPackage or (callPackageBy call);
    in
    mapAttrs (
      _: abs:
      let
        package = abs + "/package.nix";
        pins = abs + "/pins.nix";
        overrides = if pathExists pins then call pins { } else { };
      in
      if pathExists package then
        callPackage package overrides
      else
        let
          default = abs + "/default.nix";
        in
        if pathExists default then call default overrides else import (abs + "/overlay.nix") final prev
    ) paths;
}

{ lib }:

let
  inherit (builtins) intersectAttrs;
  inherit (lib)
    functionArgs
    isFunction
    mirrorFunctionArgs
    isAttrs
    setFunctionArgs
    optionalAttrs
    flip
    head
    isDerivation
    listToAttrs
    mapAttrs
    seq
    flatten
    deepSeq
    extends
    toFunction
    id
    ;

in
rec {

  overrideDerivation =
    drv: f:
    let
      newDrv = derivation (drv.drvAttrs // (f drv));
    in
    flip (extendDerivation (seq drv.drvPath true)) newDrv (
      {
        meta = drv.meta or { };
        passthru = if drv ? passthru then drv.passthru else { };
      }
      // (drv.passthru or { })
      // optionalAttrs (drv ? __spliced) {
        __spliced = { } // (mapAttrs (_: sDrv: overrideDerivation sDrv f) drv.__spliced);
      }
    );

  makeOverridable =
    f:
    let
      # Creates a functor with the same arguments as f
      mirrorArgs = mirrorFunctionArgs f;
      # Recover overrider and additional attributes for f
      # When f is a callable attribute set,
      # it may contain its own `f.override` and additional attributes.
      # This helper function recovers those attributes and decorate the overrider.
      recoverMetadata =
        if isAttrs f then
          fDecorated:
          # Preserve additional attributes for f
          f
          // fDecorated
          # Decorate f.override if presented
          // lib.optionalAttrs (f ? override) { override = fdrv: makeOverridable (f.override fdrv); }
        else
          id;
      decorate = f': recoverMetadata (mirrorArgs f');
    in
    decorate (
      origArgs:
      let
        result = f origArgs;

        # Changes the original arguments with (potentially a function that returns) a set of new attributes
        overrideWith = newArgs: origArgs // (if isFunction newArgs then newArgs origArgs else newArgs);

        # Re-call the function but with different arguments
        overrideArgs = mirrorArgs (

          newArgs: makeOverridable f (overrideWith newArgs)
        );
        # Change the result of the function call by applying g to it
        overrideResult = g: makeOverridable (mirrorArgs (args: g (f args))) origArgs;
      in
      if isAttrs result then
        result
        // {
          override = overrideArgs;
          overrideDerivation = fdrv: overrideResult (x: overrideDerivation x fdrv);
          ${if result ? overrideAttrs then "overrideAttrs" else null} =

            # NOTE: part of the above documentation had to be duplicated in `mkDerivation`'s `overrideAttrs`.
            #       design/tech debt issue: https://github.com/NixOS/nixpkgs/issues/273815
            fdrv: overrideResult (x: x.overrideAttrs fdrv);
        }
      else if isFunction result then
        # Transform the result into a functor while propagating its arguments
        setFunctionArgs result (functionArgs result) // { override = overrideArgs; }
      else
        result
    );

  callPackagesWith =
    autoArgs: fn: args:
    let
      f = if isFunction fn then fn else import fn;
      auto = intersectAttrs (functionArgs f) autoArgs;
      mirrorArgs = mirrorFunctionArgs f;
      origArgs = auto // args;
      pkgs = f origArgs;
      mkAttrOverridable = name: _: makeOverridable (mirrorArgs (newArgs: (f newArgs).${name})) origArgs;
    in
    if isDerivation pkgs then
      throw (
        "function `callPackages` was called on a *single* derivation "
        + ''"${pkgs.name or "<unknown-name>"}";''
        + " did you mean to use `callPackage` instead?"
      )
    else
      mapAttrs mkAttrOverridable pkgs;

  extendDerivation =
    condition: passthru: drv:
    let
      outputs = drv.outputs or [ "out" ];

      commonAttrs =
        drv // (listToAttrs outputsList) // { all = map (x: x.value) outputsList; } // passthru;

      outputToAttrListElement = outputName: {
        name = outputName;
        value =
          commonAttrs
          // {
            inherit (drv.${outputName}) type outputName;
            outputSpecified = true;
            drvPath =
              assert condition;
              drv.${outputName}.drvPath;
            outPath =
              assert condition;
              drv.${outputName}.outPath;
          }
          //
            # TODO: give the derivation control over the outputs.
            #       `overrideAttrs` may not be the only attribute that needs
            #       updating when switching outputs.
            optionalAttrs (passthru ? overrideAttrs) {
              # TODO: also add overrideAttrs when overrideAttrs is not custom, e.g. when not splicing.
              overrideAttrs = f: (passthru.overrideAttrs f).${outputName};
            };
      };

      outputsList = map outputToAttrListElement outputs;
    in
    commonAttrs
    // {
      drvPath =
        assert condition;
        drv.drvPath;
      outPath =
        assert condition;
        drv.outPath;
    };

  hydraJob =
    drv:
    let
      outputs = drv.outputs or [ "out" ];

      commonAttrs = {
        inherit (drv) name system meta;
        inherit outputs;
      }
      // optionalAttrs (drv._hydraAggregate or false) {
        _hydraAggregate = true;
        constituents = map hydraJob (flatten drv.constituents);
      }
      // (listToAttrs outputsList);

      makeOutput =
        outputName:
        let
          output = drv.${outputName};
        in
        {
          name = outputName;
          value = commonAttrs // {
            outPath = output.outPath;
            drvPath = output.drvPath;
            type = "derivation";
            inherit outputName;
          };
        };

      outputsList = map makeOutput outputs;

      drv' = (head outputsList).value;
    in
    if drv == null then null else deepSeq drv' drv';

  makeScopeWithSplicing =
    splicePackages: newScope: otherSplices: keep: extra: f:
    makeScopeWithSplicing' { inherit splicePackages newScope; } {
      inherit
        otherSplices
        keep
        extra
        f
        ;
    };

  makeScopeWithSplicing' =
    { splicePackages, newScope }:
    {
      otherSplices,
      # Attrs from `self` which won't be spliced.
      # Avoid using keep, it's only used for a python hook workaround, added in PR #104201.
      # ex: `keep = (self: { inherit (self) aAttr; })`
      keep ? (_self: { }),
      # Additional attrs to add to the sets `callPackage`.
      # When the package is from a subset (but not a subset within a package IS #211340)
      # within `spliced0` it will be spliced.
      # When using an package outside the set but it's available from `pkgs`, use the package from `pkgs.__splicedPackages`.
      # If the package is not available within the set or in `pkgs`, such as a package in a let binding, it will not be spliced
      # ex:
      # ```
      # nix-repl> darwin.apple_sdk.frameworks.CoreFoundation
      #   «derivation ...CoreFoundation-11.0.0.drv»
      # nix-repl> darwin.CoreFoundation
      #   error: attribute 'CoreFoundation' missing
      # nix-repl> darwin.callPackage ({ CoreFoundation }: CoreFoundation) { }
      #   «derivation ...CoreFoundation-11.0.0.drv»
      # ```
      extra ? (_spliced0: { }),
      f,
    }:
    let
      spliced0 = splicePackages {
        pkgsBuildBuild = otherSplices.selfBuildBuild;
        pkgsBuildHost = otherSplices.selfBuildHost;
        pkgsBuildTarget = otherSplices.selfBuildTarget;
        pkgsHostHost = otherSplices.selfHostHost;
        pkgsHostTarget = self; # Not `otherSplices.selfHostTarget`;
        pkgsTargetTarget = otherSplices.selfTargetTarget;
      };
      spliced = extra spliced0 // spliced0 // keep self;
      self = f self // {
        newScope = scope: newScope (spliced // scope);
        callPackage = newScope spliced; # == self.newScope {};
        # N.B. the other stages of the package set spliced in are *not*
        # overridden.
        overrideScope =
          g:
          (makeScopeWithSplicing' { inherit splicePackages newScope; } {
            inherit otherSplices keep extra;
            f = extends g f;
          });
        packages = f;
      };
    in
    self;

  extendMkDerivation =
    let
      extendsWithExclusion =
        excludedNames: g: f: final:
        let
          previous = f final;
        in
        removeAttrs previous excludedNames // g final previous;
    in
    {
      constructDrv,
      excludeDrvArgNames ? [ ],
      excludeFunctionArgNames ? [ ],
      extendDrvArgs,
      inheritFunctionArgs ? true,
      transformDrv ? id,
    }:
    setFunctionArgs
      # Adds the fixed-point style support
      (
        fpargs:
        transformDrv (
          constructDrv (extendsWithExclusion excludeDrvArgNames extendDrvArgs (toFunction fpargs))
        )
      )
      # Add __functionArgs
      (
        removeAttrs (
          # Inherit the __functionArgs from the base build helper
          optionalAttrs inheritFunctionArgs (removeAttrs (functionArgs constructDrv) excludeDrvArgNames)
          # Recover the __functionArgs from the derived build helper
          // functionArgs (extendDrvArgs { })
        ) excludeFunctionArgNames
      )
    // {
      inherit
        # Expose to the result build helper.
        constructDrv
        excludeDrvArgNames
        extendDrvArgs
        transformDrv
        ;
    };

  renameCrossIndexFrom = prefix: x: {
    buildBuild = x."${prefix}BuildBuild";
    buildHost = x."${prefix}BuildHost";
    buildTarget = x."${prefix}BuildTarget";
    hostHost = x."${prefix}HostHost";
    hostTarget = x."${prefix}HostTarget";
    targetTarget = x."${prefix}TargetTarget";
  };

  renameCrossIndexTo = prefix: x: {
    "${prefix}BuildBuild" = x.buildBuild;
    "${prefix}BuildHost" = x.buildHost;
    "${prefix}BuildTarget" = x.buildTarget;
    "${prefix}HostHost" = x.hostHost;
    "${prefix}HostTarget" = x.hostTarget;
    "${prefix}TargetTarget" = x.targetTarget;
  };

  mapCrossIndex =
    f:
    {
      buildBuild,
      buildHost,
      buildTarget,
      hostHost,
      hostTarget,
      targetTarget,
    }:
    {
      buildBuild = f buildBuild;
      buildHost = f buildHost;
      buildTarget = f buildTarget;
      hostHost = f hostHost;
      hostTarget = f hostTarget;
      targetTarget = f targetTarget;
    };
}

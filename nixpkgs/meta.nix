{ lib }:

let
  inherit (lib)
    matchAttrs
    any
    all
    isDerivation
    getBin
    assertMsg
    ;
  inherit (lib.attrsets) mapAttrs' filterAttrs;
  inherit (builtins)
    isString
    match
    typeOf
    elemAt
    ;

in
rec {

  addMetaAttrs =
    newAttrs: drv:
    if drv ? overrideAttrs then
      drv.overrideAttrs (old: {
        meta = (old.meta or { }) // newAttrs;
      })
    else
      drv // { meta = (drv.meta or { }) // newAttrs; };

  dontDistribute = drv: addMetaAttrs { hydraPlatforms = [ ]; } drv;

  mapDerivationAttrset =
    f: set: lib.mapAttrs (name: pkg: if lib.isDerivation pkg then (f pkg) else pkg) set;

  defaultPriority = 5;

  setPrio = priority: addMetaAttrs { inherit priority; };

  lowPrio = setPrio 10;

  lowPrioSet = set: mapDerivationAttrset lowPrio set;

  hiPrio = setPrio (-10);

  hiPrioSet = set: mapDerivationAttrset hiPrio set;

  platformMatch =
    platform: elem:
    (
      # Check with simple string comparison if elem was a string.
      #
      # The majority of comparisons done with this function will be against meta.platforms
      # which contains a simple platform string.
      #
      # Avoiding an attrset allocation results in significant  performance gains (~2-30) across the board in OfBorg
      # because this is a hot path for nixpkgs.
      if isString elem then
        platform ? system && elem == platform.system
      else
        matchAttrs (
          # Normalize platform attrset.
          if elem ? parsed then elem else { parsed = elem; }
        ) platform
    );

  availableOn =
    platform: pkg:
    ((!pkg ? meta.platforms) || any (platformMatch platform) pkg.meta.platforms)
    && all (elem: !platformMatch platform elem) (pkg.meta.badPlatforms or [ ]);

  licensesSpdx = mapAttrs' (_key: license: {
    name = license.spdxId;
    value = license;
  }) (filterAttrs (_key: license: license ? spdxId) lib.licenses);

  getLicenseFromSpdxId =
    licstr:
    getLicenseFromSpdxIdOr licstr (
      lib.warn "getLicenseFromSpdxId: No license matches the given SPDX ID: ${licstr}" {
        shortName = licstr;
      }
    );

  getLicenseFromSpdxIdOr =
    let
      lowercaseLicenses = lib.mapAttrs' (name: value: {
        name = lib.toLower name;
        inherit value;
      }) licensesSpdx;
    in
    licstr: default: lowercaseLicenses.${lib.toLower licstr} or default;

  getExe =
    x:
    getExe' x (
      x.meta.mainProgram or (
        # This could be turned into an error when 23.05 is at end of life
        lib.warn
          "getExe: Package ${
            lib.strings.escapeNixIdentifier x.meta.name or x.pname or x.name
          } does not have the meta.mainProgram attribute. We'll assume that the main program has the same name for now, but this behavior is deprecated, because it leads to surprising errors when the assumption does not hold. If the package has a main program, please set `meta.mainProgram` in its definition to make this warning go away. Otherwise, if the package does not have a main program, or if you don't control its definition, use getExe' to specify the name to the program, such as lib.getExe' foo \"bar\"."
          lib.getName
          x
      )
    );

  getExe' =
    x: y:
    assert assertMsg (isDerivation x)
      "lib.meta.getExe': The first argument is of type ${typeOf x}, but it should be a derivation instead.";
    assert assertMsg (isString y)
      "lib.meta.getExe': The second argument is of type ${typeOf y}, but it should be a string instead.";
    assert assertMsg (match ".*/.*" y == null)
      "lib.meta.getExe': The second argument \"${y}\" is a nested path with a \"/\" character, but it should just be the name of the executable instead.";
    "${getBin x}/bin/${y}";

  cpeFullVersionWithVendor = vendor: version: {
    inherit vendor version;
    update = "*";
  };

  tryCPEPatchVersionInUpdateWithVendor =
    vendor: version:
    let
      regex = "([0-9]+\\.[0-9]+)\\.([0-9]+)";
      # we have to call toString here in case version is an attrset with __toString attribute
      versionMatch = builtins.match regex (toString version);
    in
    if versionMatch == null then
      {
        success = false;
        error = "version ${version} doesn't match regex `${regex}`";
      }
    else
      {
        success = true;
        value = {
          inherit vendor;
          version = elemAt versionMatch 0;
          update = elemAt versionMatch 1;
        };
      };

  cpePatchVersionInUpdateWithVendor =
    vendor: version:
    let
      result = tryCPEPatchVersionInUpdateWithVendor vendor version;
    in
    if result.success then result.value else throw result.error;
}

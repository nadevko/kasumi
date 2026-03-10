{ lib }:

rec {

  inherit (builtins) compareVersions;

  splitVersion = builtins.splitVersion;

  major = v: builtins.elemAt (splitVersion v) 0;

  minor = v: builtins.elemAt (splitVersion v) 1;

  patch = v: builtins.elemAt (splitVersion v) 2;

  majorMinor = v: builtins.concatStringsSep "." (lib.take 2 (splitVersion v));

  pad =
    n: version:
    let
      numericVersion = lib.head (lib.splitString "-" version);
      versionSuffix = lib.removePrefix numericVersion version;
    in
    lib.concatStringsSep "." (lib.take n (lib.splitVersion numericVersion ++ lib.genList (_: "0") n))
    + versionSuffix;

}

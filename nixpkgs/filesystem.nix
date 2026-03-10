{ lib }:

# Tested in lib/tests/filesystem.sh
let
  inherit (builtins) pathExists toString;

  inherit (lib.filesystem) pathIsDirectory pathType packagesFromDirectoryRecursive;

  inherit (lib.strings) hasSuffix;
in

{
  inherit (builtins) baseNameOf dirOf isPath;

  inherit (builtins) readDir readFileType hashFile;

  pathType = builtins.readFileType;

  pathIsDirectory = path: pathExists path && pathType path == "directory";

  pathIsRegularFile = path: pathExists path && pathType path == "regular";

  haskellPathsInDir =
    root:
    let
      # Files in the root
      root-files = builtins.attrNames (builtins.readDir root);
      # Files with their full paths
      root-files-with-paths = map (file: {
        name = file;
        value = root + "/${file}";
      }) root-files;
      # Subdirectories of the root with a cabal file.
      cabal-subdirs = builtins.filter (
        { name, value }: builtins.pathExists (value + "/${name}.cabal")
      ) root-files-with-paths;
    in
    builtins.listToAttrs cabal-subdirs;

  locateDominatingFile =
    pattern: file:
    let
      go =
        path:
        let
          files = builtins.attrNames (builtins.readDir path);
          matches = builtins.filter (match: match != null) (map (builtins.match pattern) files);
        in
        if builtins.length matches != 0 then
          { inherit path matches; }
        else if path == /. then
          null
        else
          go (dirOf path);
      parent = dirOf file;
      isDir =
        let
          base = baseNameOf file;
          type = (builtins.readDir parent).${base} or null;
        in
        file == /. || type == "directory";
    in
    go (if isDir then file else parent);

  listFilesRecursive =
    let
      # We only flatten at the very end, as flatten is recursive.
      internalFunc =
        dir:
        (lib.mapAttrsToList (
          name: type: if type == "directory" then internalFunc (dir + "/${name}") else dir + "/${name}"
        ) (builtins.readDir dir));
    in
    dir: lib.flatten (internalFunc dir);

  packagesFromDirectoryRecursive =
    let
      inherit (lib)
        concatMapAttrs
        id
        makeScope
        recurseIntoAttrs
        removeSuffix
        ;

      # Generate an attrset corresponding to a given directory.
      # This function is outside `packagesFromDirectoryRecursive`'s lambda expression,
      #  to prevent accidentally using its parameters.
      processDir =
        { callPackage, directory, ... }@args:
        concatMapAttrs (
          name: type:
          # for each directory entry
          let
            path = directory + "/${name}";
          in
          if type == "directory" then
            {
              # recurse into directories
              "${name}" = packagesFromDirectoryRecursive (args // { directory = path; });
            }
          else if type == "regular" && hasSuffix ".nix" name then
            {
              # call .nix files
              "${removeSuffix ".nix" name}" = callPackage path { };
            }
          else if type == "regular" then
            {
              # ignore non-nix files
            }
          else
            throw ''
              lib.filesystem.packagesFromDirectoryRecursive: Unsupported file type ${type} at path ${toString path}
            ''
        ) (builtins.readDir directory);
    in
    {
      callPackage,
      newScope ? throw "lib.packagesFromDirectoryRecursive: newScope wasn't passed in args",
      directory,
    }@args:
    let
      defaultPath = directory + "/package.nix";
    in
    if pathExists defaultPath then
      # if `${directory}/package.nix` exists, call it directly
      callPackage defaultPath { }
    else if args ? newScope then
      # Create a new scope and mark it `recurseForDerivations`.
      # This lets the packages refer to each other.
      # See:
      #  [lib.makeScope](https://nixos.org/manual/nixpkgs/unstable/#function-library-lib.customisation.makeScope) and
      #  [lib.recurseIntoAttrs](https://nixos.org/manual/nixpkgs/unstable/#function-library-lib.customisation.makeScope)
      recurseIntoAttrs (
        makeScope newScope (
          self:
          # generate the attrset representing the directory, using the new scope's `callPackage` and `newScope`
          processDir (args // { inherit (self) callPackage newScope; })
        )
      )
    else
      processDir args;

  resolveDefaultNix =
    v:
    if pathIsDirectory v then
      v + "/default.nix"
    else if lib.isString v && hasSuffix "/" v then
      # A path ending in `/` can only refer to a directory, so we take the hint, even if we can't verify the validity of the path's `/` assertion.
      # A `/` is already present, so we don't add another one.
      v + "default.nix"
    else
      v;
}

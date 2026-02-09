{
  description = "Nixpkgs Deconstruction Initiative";

  nixConfig = {
    extra-experimental-features = [
      "pipe-operators"
      "no-url-literals"
    ];
    extra-substituters = [ "https://kasumi.cachix.org" ];
    extra-trusted-public-keys = [ "kasumi.cachix.org-1:ymQ5ardABxeR1WrQX+NAvohAh2GL8aAv5W6osujKbG8=" ];
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
      so = self.overlays;
    in
    {
      inherit lib;

      templates = lib.filesystem.readTemplates { default = "unstable"; } ./templates;

      overlays = {
        default = import ./overlay.nix;
        lib = import ./overlays/lib.nix;
        augment = lib.augmentLib so.lib;
        compat = import ./overlays/compat.nix;
      };

      legacyPackages = lib.importPkgsForAll nixpkgs {
        overlays = [
          so.compat
          so.default
        ];
      };

      packages = lib.forAllPkgs nixpkgs { } (pkgs: lib.makeLayer so.default pkgs |> lib.collapseLayer);

      formatter = lib.forAllPkgs self { } <| builtins.getAttr "kasumi-fmt";
      devShells = lib.forAllPkgs self { } (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });
    };
}

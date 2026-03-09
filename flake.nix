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

  outputs =
    { self, ... }:
    let
      lib = import ./lib { lib = so.builtins {} {}; };
      so = self.overlays;
    in
    {
      inherit lib;

      overlays = {
        default = import ./overlay.nix;

        lib = import ./overlays/lib.nix;
        builtins = import ./overlays/builtins.nix;
        polyfills = import ./overlays/polyfills.nix;
        shadow = import ./overlays/shadow.nix;

        augment = lib.augmentLib so.lib;
        compat = import ./overlays/compat.nix;
      };

      formatter = lib.forAllPkgs self { } <| builtins.getAttr "kasumi-fmt";
      devShells = lib.forAllPkgs self { } (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });
    };
}

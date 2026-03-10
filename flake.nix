{
  description = "Nixpkgs Deconstruction Initiative // Library";

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
      lib = import ./lib { lib = self.builtins; };
      so = self.overlays;
    in
    {
      inherit lib;
      builtins = so.relude { } { };

      overlays = {
        relude = import ./overlays/relude.nix;
        polyfills = import ./overlays/polyfills.nix;
        shadow = import ./overlays/shadow.nix;
        lib = import ./overlays/lib.nix;
      };
    };
}

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
      so = self.overlays;
    in
    {
      polyfills = so.polyfills self.lib builtins;
      shadow = self.polyfills // so.shadow self.lib self.polyfills;
      prim = self.shadow // so.prim self.lib self.shadow;
      lib = self.prim // so.lib self.lib self.prim;

      overlays = {
        polyfills = import ./overlays/00-polyfills.nix;
        shadow = import ./overlays/01-shadow.nix;
        prim = import ./overlays/02-prim.nix;
        lib = import ./overlays/03-lib.nix;
      };
    };
}

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
      compat = so.compat self.lib builtins;
      shadow = self.compat // so.shadow self.lib self.compat;
      prim = self.shadow // so.prim self.lib self.shadow;
      lib = self.prim // so.lib self.lib self.prim;

      overlays = {
        compat = import ./overlays/compat.nix;
        shadow = import ./overlays/shadow.nix;
        prim = import ./overlays/prim.nix;
        lib = import ./overlays/lib.nix;
      };
    };
}

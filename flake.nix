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
      compat = so.compat self.compat builtins;
      shadow = self.compat // so.shadow self.shadow self.compat;
      primops = self.shadow // so.primops self.primops self.shadow;
      lib = self.primops // so.lib self.lib self.primops;

      overlays = {
        compat = import ./overlays/compat.nix;
        shadow = import ./overlays/shadow.nix;
        primops = import ./overlays/primops.nix;
        lib = import ./overlays/lib.nix;
      };
    };
}

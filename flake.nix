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
    { ... }:
    {
      compat = import ./compat { };
      primops = import ./primops { };
      lib = import ./lib { };

      overlays = {
        compat = import ./compat/overlay.nix;
        primops = import ./primops/overlay.nix;
        lib = import ./lib/overlay.nix;
      };
    };
}

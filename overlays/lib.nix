final: prev: {
  prelude = import ../lib/prelude.nix final prev;
  reflect = import ../lib/reflect.nix final prev;
}

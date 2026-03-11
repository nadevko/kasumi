final: prev:
builtins.readDir ./.
|> builtins.mapAttrs (
  n: v: {
    name = if v == "regular" then builtins.substring 0 (builtins.stringLength n - 4) n else n;
    value = import ./${n} final prev;
  }
)
|> builtins.attrValues
|> builtins.listToAttrs

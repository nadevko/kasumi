# like in nix (Nix) 2.31.3
# - [builtins.bitAnd](https://github.com/NixOS/nix/blob/2.31.3/src/libexpr/primops.cc#L4214-L4228)
# - [builtins.bitOr](https://github.com/NixOS/nix/blob/2.31.3/src/libexpr/primops.cc#L4230-L4245)
# - [builtins.bitXor](https://github.com/NixOS/nix/blob/2.31.3/src/libexpr/primops.cc#L4247-L4262)
{
  genList ? builtins.genList,
  map ? builtins.map,
  elemAt ? builtins.elemAt,
  ...
}:
rec {
  range = genList (x: x) 16;
  mkTable = op: map (a: map (b: apply4 op a b) range) range;

  tableAnd = mkTable (a: b: if a == 1 && b == 1 then 1 else 0);
  tableOr = mkTable (a: b: if a == 1 || b == 1 then 1 else 0);
  tableXor = mkTable (a: b: if a != b then 1 else 0);

  apply4 =
    op: a: b:
    let
      get =
        n: i:
        let
          # n % 2
          div =
            if i == 0 then
              1
            else if i == 1 then
              2
            else if i == 2 then
              4
            else
              8;
        in
        (n / div) - ((n / div) / 2 * 2);
      r0 = op (get a 0) (get b 0);
      r1 = op (get a 1) (get b 1);
      r2 = op (get a 2) (get b 2);
      r3 = op (get a 3) (get b 3);
    in
    r0 + r1 * 2 + r2 * 4 + r3 * 8;

  bitOp =
    table:
    let
      recurse =
        a: b:
        if a == 0 && b == 0 then
          0
        else
          let
            # n % 16
            a_p = a - (a / 16 * 16);
            b_p = b - (b / 16 * 16);
            res = elemAt (elemAt table a_p) b_p;
          in
          res + 16 * (recurse (a / 16) (b / 16));
    in
    a: b:
    assert a >= 0 && b >= 0;
    if a == b then a else recurse a b;
}

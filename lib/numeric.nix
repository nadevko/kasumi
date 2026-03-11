final: prev:
let
  inherit (final.types) isInt;
  inherit (final.lists)
    reverse
    fold'
    head
    tail
    at
    lt
    ;
  inherit (final.strings) joinMap match;
  inherit (final.prelude) flip;

  inherit (final.numeric)
    toIntWith
    toBaseDigits
    max
    min
    sub
    ;
in
{
  # --- operations ------------------------------------------------------------
  mod = base: int: base - (int * (base / int));

  # --- comparators -----------------------------------------------------------
  gt = flip lt;
  le = a: b: !lt b a;
  ge = a: b: !lt a b;

  # --- extremes --------------------------------------------------------------
  min = a: b: if a < b then a else b;
  max = a: b: if a > b then a else b;

  minimum = xs: fold' min (head xs) <| tail xs;
  maximum = xs: fold' max (head xs) <| tail xs;

  clamp =
    minX: maxX: x:
    max minX <| min x maxX x;

  bitNot = sub (-1);

  toIntWith =
    base: alphabet: i:
    joinMap (at alphabet) <| toBaseDigits base i;

  fromHex = str: (fromTOML "i=0x${at (match "(0x)?([0-7]?[0-9A-Fa-f]{1,15})" str) 1}").i;

  toHex = toIntWith 16 [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "A"
    "B"
    "C"
    "D"
    "E"
    "F"
  ];

  toBaseDigits =
    base: i:
    let
      recurse =
        i:
        if i < base then
          [ i ]
        else
          let
            r = i - ((i / base) * base);
            q = (i - r) / base;
          in
          [ r ] ++ recurse q;
    in
    assert isInt base;
    assert isInt i;
    assert base >= 2;
    assert i >= 0;
    reverse <| recurse i;
}

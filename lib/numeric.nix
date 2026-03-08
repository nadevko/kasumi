final: prev:
let
  inherit (builtins)
    elemAt
    match
    isInt
    lessThan
    sub
    ;

  inherit (prev.lists) reverseList;
  inherit (prev.strings) concatMapStrings;

  inherit (final.trivial) flip;

  inherit (final.numeric)
    encodeIntWith
    toBaseDigits
    max
    min
    ;
in
{
  gt = flip lessThan;
  le = a: b: !lessThan b a;
  ge = a: b: !lessThan a b;

  min = a: b: if a < b then a else b;
  max = a: b: if a > b then a else b;
  mod = base: int: base - (int * (base / int));

  bitNot = sub (-1);

  clamp =
    minX: maxX: x:
    max minX <| min x maxX x;

  encodeIntWith =
    base: alphabet: i:
    concatMapStrings (elemAt alphabet) <| toBaseDigits base i;

  fromHex = str: (fromTOML "i=0x${elemAt (match "(0x)?([0-7]?[0-9A-Fa-f]{1,15})" str) 1}").i;

  toHex = encodeIntWith 16 [
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
    reverseList <| recurse i;
}

final: prev:
let
  inherit (final.prelude) flip;
  inherit (final.lists)
    foldl'
    generate
    head
    size
    tail
    ;
  inherit (final.numeric)
    abs
    add
    band
    shiftr
    bnot
    bor
    cdiv
    div
    epsEq
    epsilon
    floor
    int
    isEven
    max
    min
    mod
    mul
    pow
    rem
    sub
    sum
    bceil
    ;
in
{
  # --- language operators ----------------------------------------------------
  neg = x: -x;
  fdiv = a: b: a / b;

  gt = a: b: a > b;
  le = a: b: a <= b;
  ge = a: b: a >= b;

  bnot = sub (-1);
  bimp = a: b: bor (bnot a) b;

  # --- constants -------------------------------------------------------------
  pi = 3.1415926535897932;
  euler = 2.7182818284590452;
  tau = 6.2831853071795865;
  phi = 1.6180339887498948;
  epsilon = 2.2e-16;

  # --- math operations -------------------------------------------------------
  abs = x: if x < 0 then -x else x;
  rem = a: b: a - (b * (div a b));
  mod =
    a: b:
    let
      r = rem a b;
    in
    if r == 0 then
      0
    else if (a < 0) == (b < 0) then
      r
    else
      r + b;

  pow =
    x: n:
    if n == 0 then
      1
    else
      let
        half = pow x <| div n 2;
      in
      if isEven n then half * half else x * half * half;

  sum = foldl' add 0;
  product = foldl' mul 1;
  avg = a: b: (a + b) / 2.0;
  mean = xs: sum xs / size xs;
  lerp =
    a: b: t:
    a + (b - a) * t;

  # --- integers --------------------------------------------------------------
  sign =
    x:
    if x < 0 then
      -1
    else if x == 0 then
      0
    else
      1;
  square = x: x * x;
  cube = x: x * x * x;
  cdiv = a: b: div (a + b - 1) b;

  int = x: if x >= 0 then floor x else -floor (0 - x);

  round =
    x:
    let
      intPart = int x;
      frac = x - intPart;
    in
    if epsEq epsilon (frac - 0.5) 0 then
      if isEven intPart then intPart else intPart + 1
    else if frac < 0.5 then
      intPart
    else
      intPart + 1;

  # --- bitwise ---------------------------------------------------------------
  isPow2 = x: x > 0 && (band x <| x - 1) == 0;
  bceil =
    x:
    let
      step = n: x: bor x <| shiftr x n;
    in
    sub x 1 |> step 1 |> step 2 |> step 4 |> step 8 |> step 16 |> step 32 |> flip add 1;

  shiftl = x: n: x * (pow 2 n);
  shiftr = x: n: div x (pow 2 n);

  bfloor = x: if x <= 1 then 1 else shiftr (bceil x) 1;
  popCount =
    x:
    let
      recurse = n: acc: if n == 0 then acc else recurse (band n <| sub n 1) (add acc 1);
    in
    recurse x 0;
  countLeadingZeros =
    x:
    if x == 0 then
      64
    else
      let
        recurse = n: acc: if n <= 1 then acc else recurse (shiftr n 1) (add acc 1);
      in
      sub 64 (recurse (bceil x) 0);

  alignUp = align: x: cdiv x align * align;
  alignDown = align: x: div x align * align;
  isAligned = align: x: mod x align == 0;

  # --- parity / checks -------------------------------------------------------
  isEven = x: mod x 2 == 0;
  isOdd = x: mod x 2 != 0;

  hasFraction = x: floor x != x;
  epsEq =
    eps: a: b:
    abs (a - b) < eps;

  # --- extremes --------------------------------------------------------------
  min = a: b: if a < b then a else b;
  max = a: b: if b < a then a else b;
  minimum = xs: foldl' min (head xs) <| tail xs;
  maximum = xs: foldl' max (head xs) <| tail xs;

  clamp =
    low: high: x:
    max low <| min x high;

  # --- ranges ----------------------------------------------------------------
  range =
    low: high: step:
    assert step != 0;
    assert (step > 0 && high >= low) || (step < 0 && high <= low);
    generate (i: low + i * step) <| floor ((high - low) / step);

  arange =
    low: high: step:
    assert step != 0;
    assert (step > 0 && high >= low) || (step < 0 && high <= low);
    generate (i: low + i * step) <| floor ((high - low) / step) + 1;
}

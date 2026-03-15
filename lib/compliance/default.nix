final: prev:
let
  inherit (final.debug) throw;
  inherit (final.filesystem) importJson;
  inherit (final.strings) joinSep;
  inherit (final.lists)
    all
    any
    pluck
    concatMap
    ;
  inherit (final.prelude)
    id
    isString
    typeOf
    null
    true
    ;
  inherit (final.sets) assocNames;

  inherit (final.compliance)
    bySpdx
    getSpdx
    getSpdxWith
    spdxAll
    spdxAnd
    spdxAny
    spdxFields
    spdxFold
    spdxOr
    spdxPlus
    spdxPrios
    spdxWith
    toSpdxExpr
    ;
in
{
  # --- SPDX ------------------------------------------------------------------
  inherit (importJson ./by-spdx.json) bySpdx spdxVersion spdxDate;
  spdxFields = [
    "exception"
    "osiApproved"
    "fsfLibre"
    "nixFree"
    "nixRedistributable"
  ];
  spdxPrios = {
    " OR " = 1;
    " AND " = 2;
    " WITH " = 3;
  };

  getSpdx = getSpdxWith bySpdx;
  getSpdxWith =
    bySpdx: n:
    let
      x =
        if isString n then
          bySpdx.${n} or (throw "compliance.getSpdx: unknown SPDX '${n}'")
        else
          assert
            x ? type && x.type == "spdx"
            || throw "compliance.getSpdx: 'string' or 'spdx' are expected but got '${typeOf n}'";
          n;
    in
    if x ? __toString then x else x // { __toString = toSpdxExpr; };

  toSpdxExpr =
    spdx:
    if spdx ? sep then
      joinSep spdx.sep
      <| map (
        x:
        let
          expr = toSpdxExpr x;
        in
        if (spdxPrios.${x.sep} or 3) < spdxPrios.${spdx.sep} then "(${expr})" else expr
      ) spdx.args
    else
      spdx.id;

  spdx = {
    __nixPath = bySpdx;
    __findFile = getSpdxWith;
    __mul = spdxAnd;
    __sub = a: b: if a == 0 then spdxPlus b else spdxOr a b;
    __div = spdxWith;
  };

  # --- SPDX Combinators ------------------------------------------------------
  spdxFold =
    sep: comparator: xs:
    let
      xs' = concatMap (
        x:
        let
          x' = getSpdx x;
        in
        if x' ? sep && x'.sep == sep then x'.args else [ x' ]
      ) xs;
    in
    assert
      all (x: !x.exception) xs' || throw "compliance.spdxFold: exceptions cannot be combined with AND/OR";
    {
      type = "spdx";
      inherit sep;
      args = xs';
      __toString = toSpdxExpr;
    }
    // assocNames (field: comparator <| pluck field xs') spdxFields;

  spdxAll = spdxFold " AND " <| all id;
  spdxAny = spdxFold " OR " <| any id;
  spdxAnd =
    a: b:
    spdxAll [
      a
      b
    ];
  spdxOr =
    a: b:
    spdxAny [
      a
      b
    ];

  spdxWith =
    a: b:
    let
      a' = getSpdx a;
      b' = getSpdx b;
    in
    assert
      !a' ? sep && !a'.exception || throw "compliance.spdxWith: left operand must be a plain license";
    assert !b' ? sep && b'.exception || throw "compliance.spdxWith: right operand must be an exception";
    {
      type = "spdx";
      sep = " WITH ";
      args = [
        a'
        b'
      ];
      __toString = toSpdxExpr;
    }
    // assocNames (
      field:
      all id
      <| pluck field [
        a'
        b'
      ]
    ) spdxFields;

  spdxPlus =
    x:
    let
      x' = getSpdx x;
    in
    assert
      !(x' ? sep) && !(x' ? plus) || throw "compliance.spdxPlus: cannot apply + to a compound expression";
    assert
      x' ? later || throw "compliance.spdxPlus: ${x'.id} is not a versioned license, + is meaningless";
    assert
      x'.later != null
      || throw "compliance.spdxPlus: ${x'.id} is a GNU license, use -only or -or-later suffix explicitly";
    spdxAny (map getSpdx x'.later)
    // {
      plus = true;
      __toString = _: x'.id + "+";
    };
}

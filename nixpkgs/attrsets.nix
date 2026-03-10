{ lib }:

let
  inherit (builtins) head length;
  inherit (lib.trivial) mergeAttrs;
  inherit (lib.strings)
    concatStringsSep
    concatMapStringsSep
    escapeNixIdentifier
    sanitizeDerivationName
    ;
  inherit (lib.lists)
    filter
    foldr
    foldl'
    concatMap
    elemAt
    all
    partition
    groupBy
    take
    foldl
    ;
in

rec {
  inherit (builtins)
    attrNames
    listToAttrs
    hasAttr
    isAttrs
    getAttr
    removeAttrs
    intersectAttrs
    ;

  attrByPath =
    attrPath: default: set:
    let
      lenAttrPath = length attrPath;
      attrByPath' =
        n: s:
        (
          if n == lenAttrPath then
            s
          else
            (
              let
                attr = elemAt attrPath n;
              in
              if s ? ${attr} then attrByPath' (n + 1) s.${attr} else default
            )
        );
    in
    attrByPath' 0 set;

  hasAttrByPath =
    attrPath: e:
    let
      lenAttrPath = length attrPath;
      hasAttrByPath' =
        n: s:
        (
          n == lenAttrPath
          || (
            let
              attr = elemAt attrPath n;
            in
            if s ? ${attr} then hasAttrByPath' (n + 1) s.${attr} else false
          )
        );
    in
    hasAttrByPath' 0 e;

  longestValidPathPrefix =
    attrPath: v:
    let
      lenAttrPath = length attrPath;
      getPrefixForSetAtIndex =
        # The nested attribute set to check, if it is an attribute set, which
        # is not a given.
        remainingSet:
        # The index of the attribute we're about to check, as well as
        # the length of the prefix we've already checked.
        remainingPathIndex:

        if remainingPathIndex == lenAttrPath then
          # All previously checked attributes exist, and no attr names left,
          # so we return the whole path.
          attrPath
        else
          let
            attr = elemAt attrPath remainingPathIndex;
          in
          if remainingSet ? ${attr} then
            getPrefixForSetAtIndex remainingSet.${attr} # advance from the set to the attribute value
              (remainingPathIndex + 1) # advance the path
          else
            # The attribute doesn't exist, so we return the prefix up to the
            # previously checked length.
            take remainingPathIndex attrPath;
    in
    getPrefixForSetAtIndex v 0;

  setAttrByPath =
    attrPath: value:
    let
      len = length attrPath;
      atDepth = n: if n == len then value else { ${elemAt attrPath n} = atDepth (n + 1); };
    in
    atDepth 0;

  getAttrFromPath =
    attrPath: set:
    attrByPath attrPath (abort ("cannot find attribute '" + concatStringsSep "." attrPath + "'")) set;

  concatMapAttrs = f: v: foldl' mergeAttrs { } (attrValues (mapAttrs f v));

  updateManyAttrsByPath =
    let
      # When recursing into attributes, instead of updating the `path` of each
      # update using `tail`, which needs to allocate an entirely new list,
      # we just pass a prefix length to use and make sure to only look at the
      # path without the prefix length, so that we can reuse the original list
      # entries.
      go =
        prefixLength: hasValue: value: updates:
        let
          # Splits updates into ones on this level (split.right)
          # And ones on levels further down (split.wrong)
          split = partition (el: length el.path == prefixLength) updates;

          # Groups updates on further down levels into the attributes they modify
          nested = groupBy (el: elemAt el.path prefixLength) split.wrong;

          # Applies only nested modification to the input value
          withNestedMods =
            # Return the value directly if we don't have any nested modifications
            if split.wrong == [ ] then
              if hasValue then
                value
              else
                # Throw an error if there is no value. This `head` call here is
                # safe, but only in this branch since `go` could only be called
                # with `hasValue == false` for nested updates, in which case
                # it's also always called with at least one update
                let
                  updatePath = (head split.right).path;
                in
                throw (
                  "updateManyAttrsByPath: Path '${showAttrPath updatePath}' does "
                  + "not exist in the given value, but the first update to this "
                  + "path tries to access the existing value."
                )
            else
            # If there are nested modifications, try to apply them to the value
            if !hasValue then
              # But if we don't have a value, just use an empty attribute set
              # as the value, but simplify the code a bit
              mapAttrs (name: go (prefixLength + 1) false null) nested
            else if isAttrs value then
              # If we do have a value and it's an attribute set, override it
              # with the nested modifications
              value // mapAttrs (name: go (prefixLength + 1) (value ? ${name}) value.${name}) nested
            else
              # However if it's not an attribute set, we can't apply the nested
              # modifications, throw an error
              let
                updatePath = (head split.wrong).path;
              in
              throw (
                "updateManyAttrsByPath: Path '${showAttrPath updatePath}' needs to "
                + "be updated, but path '${showAttrPath (take prefixLength updatePath)}' "
                + "of the given value is not an attribute set, so we can't "
                + "update an attribute inside of it."
              );

          # We get the final result by applying all the updates on this level
          # after having applied all the nested updates
          # We use foldl instead of foldl' so that in case of multiple updates,
          # intermediate values aren't evaluated if not needed
        in
        foldl (acc: el: el.update acc) withNestedMods split.right;

    in
    updates: value: go 0 true value updates;

  attrVals = nameList: set: map (x: set.${x}) nameList;

  attrValues = builtins.attrValues;

  getAttrs = names: attrs: genAttrs names (name: attrs.${name});

  catAttrs = builtins.catAttrs;

  filterAttrs = pred: set: removeAttrs set (filter (name: !pred name set.${name}) (attrNames set));

  filterAttrsRecursive =
    pred: set:
    listToAttrs (
      concatMap (
        name:
        let
          v = set.${name};
        in
        if pred name v then
          [ (nameValuePair name (if isAttrs v then filterAttrsRecursive pred v else v)) ]
        else
          [ ]
      ) (attrNames set)
    );

  foldlAttrs =
    f: init: set:
    foldl' (acc: name: f acc name set.${name}) init (attrNames set);

  foldAttrs =
    op: nul: list_of_attrs:
    foldr (
      n: a: foldr (name: o: o // { ${name} = op n.${name} (a.${name} or nul); }) a (attrNames n)
    ) { } list_of_attrs;

  collect =
    pred: attrs:
    if pred attrs then
      [ attrs ]
    else if isAttrs attrs then
      concatMap (collect pred) (attrValues attrs)
    else
      [ ];

  cartesianProduct =
    attrsOfLists:
    foldl' (
      listOfAttrs: attrName:
      concatMap (
        attrs: map (listValue: attrs // { ${attrName} = listValue; }) attrsOfLists.${attrName}
      ) listOfAttrs
    ) [ { } ] (attrNames attrsOfLists);

  mapCartesianProduct = f: attrsOfLists: map f (cartesianProduct attrsOfLists);

  nameValuePair = name: value: { inherit name value; };

  mapAttrs = builtins.mapAttrs;

  mapAttrs' = f: set: listToAttrs (mapAttrsToList f set);

  mapAttrsToList = f: attrs: attrValues (mapAttrs f attrs);

  attrsToList = mapAttrsToList nameValuePair;

  mapAttrsRecursive = f: set: mapAttrsRecursiveCond (as: true) f set;

  mapAttrsRecursiveCond =
    cond: f: set:
    let
      recurse =
        path:
        mapAttrs (
          name: value:
          if isAttrs value && cond value then recurse (path ++ [ name ]) value else f (path ++ [ name ]) value
        );
    in
    recurse [ ] set;

  mapAttrsToListRecursive = mapAttrsToListRecursiveCond (_: _: true);

  mapAttrsToListRecursiveCond =
    pred: f: set:
    let
      mapRecursive =
        path: value: if isAttrs value && pred path value then recurse path value else [ (f path value) ];
      recurse = path: set: concatMap (name: mapRecursive (path ++ [ name ]) set.${name}) (attrNames set);
    in
    recurse [ ] set;

  genAttrs = names: f: genAttrs' names (n: nameValuePair n (f n));

  genAttrs' = xs: f: listToAttrs (map f xs);

  isDerivation = value: value.type or null == "derivation";

  toDerivation =
    path:
    let
      path' = builtins.storePath path;
      res = {
        type = "derivation";
        name = sanitizeDerivationName (builtins.substring 33 (-1) (baseNameOf path'));
        outPath = path';
        outputs = [ "out" ];
        out = res;
        outputName = "out";
      };
    in
    res;

  optionalAttrs = cond: as: if cond then as else { };

  zipAttrsWithNames =
    names: f: sets:
    listToAttrs (
      map (name: {
        inherit name;
        value = f name (catAttrs name sets);
      }) names
    );

  zipAttrsWith =
    builtins.zipAttrsWith or (f: sets: zipAttrsWithNames (concatMap attrNames sets) f sets);

  zipAttrs = zipAttrsWith (name: values: values);

  mergeAttrsList =
    list:
    let
      # `binaryMerge start end` merges the elements at indices `index` of `list` such that `start <= index < end`
      # Type: Int -> Int -> AttrSet
      binaryMerge =
        start: end:
        # assert start < end; # Invariant
        if end - start >= 2 then
          # If there's at least 2 elements, split the range in two, recurse on each part and merge the result
          # The invariant is satisfied because each half will have at least 1 element
          binaryMerge start (start + (end - start) / 2) // binaryMerge (start + (end - start) / 2) end
        else
          # Otherwise there will be exactly 1 element due to the invariant, in which case we just return it directly
          elemAt list start;
    in
    if list == [ ] then
      # Calling binaryMerge as below would not satisfy its invariant
      { }
    else
      binaryMerge 0 (length list);

  recursiveUpdateUntil =
    pred: lhs: rhs:
    let
      f =
        attrPath:
        zipAttrsWith (
          name: values:
          let
            here = attrPath ++ [ name ];
          in
          if length values == 1 || pred here (elemAt values 1) (head values) then
            head values
          else
            f here values
        );
    in
    f [ ] [ rhs lhs ];

  recursiveUpdate =
    lhs: rhs:
    recursiveUpdateUntil (
      path: lhs: rhs:
      !(isAttrs lhs && isAttrs rhs)
    ) lhs rhs;

  matchAttrs =
    pattern: attrs:
    assert isAttrs pattern;
    all (
      # Compare equality between `pattern` & `attrs`.
      attr:
      # Missing attr, not equal.
      attrs ? ${attr}
      && (
        let
          lhs = pattern.${attr};
          rhs = attrs.${attr};
        in
        # If attrset check recursively
        if isAttrs lhs then isAttrs rhs && matchAttrs lhs rhs else lhs == rhs
      )
    ) (attrNames pattern);

  overrideExisting = old: new: mapAttrs (name: value: new.${name} or value) old;

  showAttrPath =
    path:
    if path == [ ] then "<root attribute path>" else concatMapStringsSep "." escapeNixIdentifier path;

  getOutput =
    output: pkg:
    if !pkg ? outputSpecified || !pkg.outputSpecified then pkg.${output} or pkg.out or pkg else pkg;

  getFirstOutput =
    candidates: pkg:
    let
      outputs = builtins.filter (name: hasAttr name pkg) candidates;
      output = builtins.head outputs;
    in
    if pkg.outputSpecified or false || outputs == [ ] then pkg else pkg.${output};

  getBin = getOutput "bin";

  getLib = getOutput "lib";

  getStatic = getFirstOutput [
    "static"
    "lib"
    "out"
  ];

  getDev = getOutput "dev";

  getInclude = getFirstOutput [
    "include"
    "dev"
    "out"
  ];

  getMan = getOutput "man";

  chooseDevOutputs = map getDev;

  recurseIntoAttrs = attrs: attrs // { recurseForDerivations = true; };

  dontRecurseIntoAttrs = attrs: attrs // { recurseForDerivations = false; };

  unionOfDisjoint =
    x: y:
    let
      intersection = builtins.intersectAttrs x y;
      collisions = lib.concatStringsSep " " (builtins.attrNames intersection);
      mask = builtins.mapAttrs (
        name: value: throw "unionOfDisjoint: collision on ${name}; complete list: ${collisions}"
      ) intersection;
    in
    (x // y) // mask;
}

# like in nix (Nix) 2.31.3
# - [builtins.parseFlakeRef](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flake-primops.cc#L59-L98)
# - [flakeref.cc](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flakeref.cc)
{
  attrNames ? builtins.attrNames,
  elemAt ? builtins.elemAt,
  filter ? builtins.filter,
  head ? builtins.head,
  isAttrs ? builtins.isAttrs,
  isString ? builtins.isString,
  listToAttrs ? builtins.listToAttrs,
  map ? builtins.map,
  match ? builtins.match,
  null ? builtins.null,
  removeAttrs ? builtins.removeAttrs,
  split ? builtins.split,
  throw ? builtins.throw,
  ...
}:
let
  removeNulls = set: removeAttrs set (filter (n: set.${n} == null) (attrNames set));

  fromMQuery =
    mQuery:
    if mQuery == null || elemAt mQuery 2 == null then
      { }
    else
      listToAttrs (filter (x: x != null) (map parseKV (filter isString (split "&" (elemAt mQuery 2)))));

  parseKV =
    kv:
    let
      m = match "([^=]+)=(.*)" kv;
    in
    if m != null then
      {
        name = head m;
        value = elemAt m 1;
      }
    else
      null;
in
ref:
if isAttrs ref then
  ref
else if match ".*#.*" ref != null then
  throw "unexpected fragment in flake reference '${ref}'"
else
  let
    mQuery = match "([^?]+)(\\?(.*))?" ref;
    base = if mQuery != null then head mQuery else ref;

    mRev = s: match "^[0-9a-f]{40}$" s;
    mId = match "^(flake:)?([a-zA-Z][a-zA-Z0-9_-]*)(/([^/]+)(/([^/]+))?)?$" base;
    mForge = match "^(github|gitlab|sourcehut):([^/]+)/([^/]+)(/([^/]+)(/([^/]+))?)?$" base;
    mPath = match "^path:(.*)$" base;
    mURL = match "^([a-zA-Z][a-zA-Z0-9.-]*)(\\+([a-zA-Z0-9+.-]+))?:(//)?(.*)$" base;
    isAbs = match "^/.*" base != null;

    result =
      if mId != null then
        let
          refOrRev = elemAt mId 3;
          rev = elemAt mId 5;
          isRev = mRev refOrRev != null;
          hasRev = rev != null;
        in
        {
          type = "indirect";
          id = elemAt mId 1;
          ${if refOrRev == null || isRev then null else "ref"} = refOrRev;
          ${if hasRev || refOrRev != null && isRev then "rev" else null} = if hasRev then rev else refOrRev;
        }
      else if mForge != null then
        let
          refOrRev = elemAt mForge 4;
          rev = elemAt mForge 6;
          isRev = mRev refOrRev != null;
          hasRev = rev != null;
        in
        {
          type = head mForge;
          owner = elemAt mForge 1;
          repo = elemAt mForge 2;
          ${if refOrRev == null || isRev then null else "ref"} = refOrRev;
          ${if hasRev || refOrRev != null && isRev then "rev" else null} = if hasRev then rev else refOrRev;
        }
      else if mPath != null then
        {
          type = "path";
          path = head mPath;
        }
      else if mURL != null then
        let
          part1 = head mURL;
          hasPlus = elemAt mURL 1 != null;
          part2 = elemAt mURL 2;
          slashes = if elemAt mURL 3 != null then "//" else "";
          rest = elemAt mURL 4;
        in
        {
          type =
            if hasPlus then
              part1
            else if part1 == "http" || part1 == "https" then
              "tarball"
            else
              part1;
          url = if hasPlus then "${part2}:${slashes}${rest}" else base;
        }
      else if isAbs then
        {
          type = "path";
          path = base;
        }
      else
        throw "invalid flake reference '${ref}'";
  in
  removeNulls result // fromMQuery mQuery

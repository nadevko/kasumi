# like in nix (Nix) 2.31.3
# - [builtins.flakeRefToString](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flake-primops.cc#L100-L158)
# - [flakeref.cc](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flakeref.cc)
{
  all ? builtins.all,
  typeOf ? builtins.typeOf,
  elem ? builtins.elem,
  throw ? builtins.throw,
  attrNames ? builtins.attrNames,
  match ? builtins.match,
  head ? builtins.head,
  filter ? builtins.filter,
  toString ? builtins.toString,
  isBool ? builtins.isBool,
  sort ? builtins.sort,
  concatStringsSep ? builtins.concatStringsSep,
  ...
}:
set:
assert all (
  name:
  let
    type = typeOf set.${name};
  in
  elem type [
    "int"
    "bool"
    "string"
  ]
  || throw "flake reference attribute sets may only contain integers, booleans, and strings, but attribute '${name}' is '${type}'"
) (attrNames set);
let
  type = set.type or (throw "flake reference is missing 'type'");

  base =
    if type == "indirect" then
      let
        id = set.id or (throw "indirect flake reference missing 'id'");
      in
      if match "^[a-zA-Z][a-zA-Z0-9_-]*$" id != null then id else "flake:${id}"
    else if
      elem type [
        "github"
        "gitlab"
        "sourcehut"
      ]
    then
      let
        owner = set.owner or (throw "missing owner");
        repo = set.repo or (throw "missing repo");
      in
      "${type}:${owner}/${repo}"
    else if type == "path" then
      "path:${set.path or (throw "missing path")}"
    else if type == "tarball" || type == "file" then
      set.url or (throw "missing url")
    else
      let
        url = set.url or (throw "missing url");
        mProto = match "^([a-z0-9-]+)://.*" url;
        urlProto = if mProto != null then head mProto else "";
        prefix =
          if urlProto != "" && type != urlProto then
            "${type}+"
          else if urlProto == "" then
            "${type}+"
          else
            "";
      in
      "${prefix}${url}";

  hasForgePath = elem type [
    "github"
    "gitlab"
    "sourcehut"
    "indirect"
  ];

  pathRefRev =
    if hasForgePath then
      if set ? ref && set ? rev then
        "/${set.ref}/${set.rev}"
      else if set ? ref then
        "/${set.ref}"
      else if set ? rev then
        "/${set.rev}"
      else
        ""
    else
      "";

  baseWithPath = base + pathRefRev;

  consumed = [
    "type"
    "id"
    "owner"
    "repo"
    "path"
    "url"
  ];
  consumedRefRev =
    if hasForgePath then
      [
        "ref"
        "rev"
      ]
    else
      [ ];
  ignoreKeys = consumed ++ consumedRefRev;

  queryKeys = filter (k: !(elem k ignoreKeys)) (attrNames set);

  toStr = v: if isBool v then (if v then "1" else "0") else toString v;
  qKeysSorted = sort (a: b: a < b) queryKeys;
  qParts = map (k: "${k}=${toStr set.${k}}") qKeysSorted;

  qs = if qParts == [ ] then "" else "?" + concatStringsSep "&" qParts;
in
baseWithPath + qs

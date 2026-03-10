{ lib }:
let

  inherit (import ./internal.nix { inherit lib; })
    _coerce
    _coerceResult
    _singleton
    _coerceMany
    _toSourceFilter
    _fromSourceFilter
    _toList
    _unionMany
    _fileFilter
    _printFileset
    _intersection
    _difference
    _fromFetchGit
    _emptyWithoutBase
    ;

  inherit (builtins)
    isBool
    isList
    isPath
    pathExists
    seq
    typeOf
    nixVersion
    ;

  inherit (lib.lists) elemAt imap0;

  inherit (lib.path) hasPrefix splitRoot;

  inherit (lib.strings) isStringLike versionOlder;

  inherit (lib.filesystem) pathType;

  inherit (lib.sources) cleanSourceWith;

  inherit (lib.trivial) isFunction pipe;

in
{

  maybeMissing =
    path:
    if !isPath path then
      if isStringLike path then
        throw ''lib.fileset.maybeMissing: Argument ("${toString path}") is a string-like value, but it should be a path instead.''
      else
        throw "lib.fileset.maybeMissing: Argument is of type ${typeOf path}, but it should be a path instead."
    else if !pathExists path then
      _emptyWithoutBase
    else
      _singleton path;

  trace =
    fileset:
    let
      # "fileset" would be a better name, but that would clash with the argument name,
      # and we cannot change that because of https://github.com/nix-community/nixdoc/issues/76
      actualFileset = _coerce "lib.fileset.trace: Argument" fileset;
    in
    seq (_printFileset actualFileset) (x: x);

  traceVal =
    fileset:
    let
      # "fileset" would be a better name, but that would clash with the argument name,
      # and we cannot change that because of https://github.com/nix-community/nixdoc/issues/76
      actualFileset = _coerce "lib.fileset.traceVal: Argument" fileset;
    in
    seq (_printFileset actualFileset)
      # We could also return the original fileset argument here,
      # but that would then duplicate work for consumers of the fileset, because then they have to coerce it again
      actualFileset;

  toSource =
    { root, fileset }:
    let
      # We cannot rename matched attribute arguments, so let's work around it with an extra `let in` statement
      filesetArg = fileset;
    in
    let
      fileset = _coerce "lib.fileset.toSource: `fileset`" filesetArg;
      rootFilesystemRoot = (splitRoot root).root;
      filesetFilesystemRoot = (splitRoot fileset._internalBase).root;
      sourceFilter = _toSourceFilter fileset;
    in
    if !isPath root then
      if root ? _isLibCleanSourceWith then
        throw ''
          lib.fileset.toSource: `root` is a `lib.sources`-based value, but it should be a path instead.
              To use a `lib.sources`-based value, convert it to a file set using `lib.fileset.fromSource` and pass it as `fileset`.
              Note that this only works for sources created from paths.''
      else if isStringLike root then
        throw ''
          lib.fileset.toSource: `root` (${toString root}) is a string-like value, but it should be a path instead.
              Paths in strings are not supported by `lib.fileset`, use `lib.sources` or derivations instead.''
      else
        throw "lib.fileset.toSource: `root` is of type ${typeOf root}, but it should be a path instead."
    # Currently all Nix paths have the same filesystem root, but this could change in the future.
    # See also ../path/README.md
    else if !fileset._internalIsEmptyWithoutBase && rootFilesystemRoot != filesetFilesystemRoot then
      throw ''
        lib.fileset.toSource: Filesystem roots are not the same for `fileset` and `root` (${toString root}):
            `root`: Filesystem root is "${toString rootFilesystemRoot}"
            `fileset`: Filesystem root is "${toString filesetFilesystemRoot}"
            Different filesystem roots are not supported.''
    else if !pathExists root then
      throw "lib.fileset.toSource: `root` (${toString root}) is a path that does not exist."
    else if pathType root != "directory" then
      throw ''
        lib.fileset.toSource: `root` (${toString root}) is a file, but it should be a directory instead. Potential solutions:
            - If you want to import the file into the store _without_ a containing directory, use string interpolation or `builtins.path` instead of this function.
            - If you want to import the file into the store _with_ a containing directory, set `root` to the containing directory, such as ${toString (dirOf root)}, and set `fileset` to the file path.''
    else if !fileset._internalIsEmptyWithoutBase && !hasPrefix root fileset._internalBase then
      throw ''
        lib.fileset.toSource: `fileset` could contain files in ${toString fileset._internalBase}, which is not under the `root` (${toString root}). Potential solutions:
            - Set `root` to ${toString fileset._internalBase} or any directory higher up. This changes the layout of the resulting store path.
            - Set `fileset` to a file set that cannot contain files outside the `root` (${toString root}). This could change the files included in the result.''
    else
      seq sourceFilter cleanSourceWith {
        name = "source";
        src = root;
        filter = sourceFilter;
      };

  toList = fileset: _toList (_coerce "lib.fileset.toList: Argument" fileset);

  union =
    fileset1: fileset2:
    _unionMany (
      _coerceMany "lib.fileset.union" [
        {
          context = "First argument";
          value = fileset1;
        }
        {
          context = "Second argument";
          value = fileset2;
        }
      ]
    );

  unions =
    filesets:
    if !isList filesets then
      throw "lib.fileset.unions: Argument is of type ${typeOf filesets}, but it should be a list instead."
    else
      pipe filesets [
        # Annotate the elements with context, used by _coerceMany for better errors
        (imap0 (
          i: el: {
            context = "Element ${toString i}";
            value = el;
          }
        ))
        (_coerceMany "lib.fileset.unions")
        _unionMany
      ];

  intersection =
    fileset1: fileset2:
    let
      filesets = _coerceMany "lib.fileset.intersection" [
        {
          context = "First argument";
          value = fileset1;
        }
        {
          context = "Second argument";
          value = fileset2;
        }
      ];
    in
    _intersection (elemAt filesets 0) (elemAt filesets 1);

  difference =
    positive: negative:
    let
      filesets = _coerceMany "lib.fileset.difference" [
        {
          context = "First argument (positive set)";
          value = positive;
        }
        {
          context = "Second argument (negative set)";
          value = negative;
        }
      ];
    in
    _difference (elemAt filesets 0) (elemAt filesets 1);

  fileFilter =
    predicate: path:
    if !isFunction predicate then
      throw "lib.fileset.fileFilter: First argument is of type ${typeOf predicate}, but it should be a function instead."
    else if !isPath path then
      if path._type or "" == "fileset" then
        throw ''
          lib.fileset.fileFilter: Second argument is a file set, but it should be a path instead.
              If you need to filter files in a file set, use `intersection fileset (fileFilter pred ./.)` instead.''
      else
        throw "lib.fileset.fileFilter: Second argument is of type ${typeOf path}, but it should be a path instead."
    else if !pathExists path then
      throw "lib.fileset.fileFilter: Second argument (${toString path}) is a path that does not exist."
    else
      _fileFilter predicate path;

  fromSource =
    source:
    let
      # This function uses `._isLibCleanSourceWith`, `.origSrc` and `.filter`,
      # which are technically internal to lib.sources,
      # but we'll allow this since both libraries are in the same code base
      # and this function is a bridge between them.
      isFiltered = source ? _isLibCleanSourceWith;
      path = if isFiltered then source.origSrc else source;
    in
    # We can only support sources created from paths
    if !isPath path then
      if isStringLike path then
        throw ''
          lib.fileset.fromSource: The source origin of the argument is a string-like value ("${toString path}"), but it should be a path instead.
              Sources created from paths in strings cannot be turned into file sets, use `lib.sources` or derivations instead.''
      else
        throw "lib.fileset.fromSource: The source origin of the argument is of type ${typeOf path}, but it should be a path instead."
    else if !pathExists path then
      throw "lib.fileset.fromSource: The source origin (${toString path}) of the argument is a path that does not exist."
    else if isFiltered then
      _fromSourceFilter path source.filter
    else
      # If there's no filter, no need to run the expensive conversion, all subpaths will be included
      _singleton path;

  gitTracked = path: _fromFetchGit "gitTracked" "argument" path { };

  gitTrackedWith =
    {
      recurseSubmodules ? false,
    }:
    path:
    if !isBool recurseSubmodules then
      throw "lib.fileset.gitTrackedWith: Expected the attribute `recurseSubmodules` of the first argument to be a boolean, but it's a ${typeOf recurseSubmodules} instead."
    else
      _fromFetchGit "gitTrackedWith" "second argument" path
        # This is the only `fetchGit` parameter that makes sense in this context.
        { submodules = recurseSubmodules; };

  empty = _emptyWithoutBase;

  isFileset = x: (_coerceResult "" x).success;
}

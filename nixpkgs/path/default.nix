# Functions for working with path values.
# See ./README.md for internal docs
{ lib }:
let

  inherit (builtins)
    isString
    isPath
    split
    match
    typeOf
    storeDir
    ;

  inherit (lib.lists)
    length
    head
    last
    genList
    elemAt
    all
    concatMap
    foldl'
    take
    drop
    ;

  listHasPrefix = lib.lists.hasPrefix;

  inherit (lib.strings) concatStringsSep substring;

  inherit (lib.asserts) assertMsg;

  inherit (lib.path.subpath) isValid;

  # Returns the reason why a subpath is invalid, or `null` if it's valid
  subpathInvalidReason =
    value:
    if !isString value then
      "The given value is of type ${builtins.typeOf value}, but a string was expected"
    else if value == "" then
      "The given string is empty"
    else if substring 0 1 value == "/" then
      "The given string \"${value}\" starts with a `/`, representing an absolute path"
    # We don't support ".." components, see ./path.md#parent-directory
    else if match "(.*/)?\\.\\.(/.*)?" value != null then
      "The given string \"${value}\" contains a `..` component, which is not allowed in subpaths"
    else
      null;

  # Split and normalise a relative path string into its components.
  # Error for ".." components and doesn't include "." components
  splitRelPath =
    path:
    let
      # Split the string into its parts using regex for efficiency. This regex
      # matches patterns like "/", "/./", "/././", with arbitrarily many "/"s
      # together. These are the main special cases:
      # - Leading "./" gets split into a leading "." part
      # - Trailing "/." or "/" get split into a trailing "." or ""
      #   part respectively
      #
      # These are the only cases where "." and "" parts can occur
      parts = split "/+(\\./+)*" path;

      # `split` creates a list of 2 * k + 1 elements, containing the k +
      # 1 parts, interleaved with k matches where k is the number of
      # (non-overlapping) matches. This calculation here gets the number of parts
      # back from the list length
      # floor( (2 * k + 1) / 2 ) + 1 == floor( k + 1/2 ) + 1 == k + 1
      partCount = length parts / 2 + 1;

      # To assemble the final list of components we want to:
      # - Skip a potential leading ".", normalising "./foo" to "foo"
      # - Skip a potential trailing "." or "", normalising "foo/" and "foo/." to
      #   "foo". See ./path.md#trailing-slashes
      skipStart = if head parts == "." then 1 else 0;
      skipEnd = if last parts == "." || last parts == "" then 1 else 0;

      # We can now know the length of the result by removing the number of
      # skipped parts from the total number
      componentCount = partCount - skipEnd - skipStart;

    in
    # Special case of a single "." path component. Such a case leaves a
    # componentCount of -1 due to the skipStart/skipEnd not verifying that
    # they don't refer to the same character
    if path == "." then
      [ ]

    # Generate the result list directly. This is more efficient than a
    # combination of `filter`, `init` and `tail`, because here we don't
    # allocate any intermediate lists
    else
      genList (
        index:
        # To get to the element we need to add the number of parts we skip and
        # multiply by two due to the interleaved layout of `parts`
        elemAt parts ((skipStart + index) * 2)
      ) componentCount;

  # Join relative path components together
  joinRelPath =
    components:
    # Always return relative paths with `./` as a prefix (./path.md#leading-dots-for-relative-paths)
    "./"
    +
      # An empty string is not a valid relative path, so we need to return a `.` when we have no components
      (if components == [ ] then "." else concatStringsSep "/" components);

  # Type: Path -> { root :: Path; components :: [String]; }
  #
  # Deconstruct a path value type into:
  # - root: The filesystem root of the path, generally `/`
  # - components: All the path's components
  #
  # This is similar to `splitString "/" (toString path)` but safer
  # because it can distinguish different filesystem roots
  deconstructPath =
    let
      recurse =
        components: base:
        # If the parent of a path is the path itself, then it's a filesystem root
        if base == dirOf base then
          {
            root = base;
            inherit components;
          }
        else
          recurse ([ (baseNameOf base) ] ++ components) (dirOf base);
    in
    recurse [ ];

  # The components of the store directory, typically [ "nix" "store" ]
  storeDirComponents = splitRelPath ("./" + storeDir);
  # The number of store directory components, typically 2
  storeDirLength = length storeDirComponents;

  # Type: [String] -> Bool
  #
  # Whether path components have a store path as a prefix, according to
  # https://nixos.org/manual/nix/stable/store/store-path.html#store-path.
  componentsHaveStorePathPrefix =
    components:
    # path starts with the store directory (typically /nix/store)
    listHasPrefix storeDirComponents components
    # is not the store directory itself, meaning there's at least one extra component
    && storeDirComponents != components
    # and the first component after the store directory has the expected format.
    # NOTE: We could change the hash regex to be [0-9a-df-np-sv-z],
    # because these are the actual ASCII characters used by Nix's base32 implementation,
    # but this is not fully specified, so let's tie this too much to the currently implemented concept of store paths.
    # Similar reasoning applies to the validity of the name part.
    # We care more about discerning store path-ness on realistic values. Making it airtight would be fragile and slow.
    && match ".{32}-.+" (elemAt components storeDirLength) != null
    # alternatively match content‐addressed derivations, which _currently_ do
    # not have a store directory prefix.
    # This is a workaround for https://github.com/NixOS/nix/issues/12361 which
    # was needed during the experimental phase of ca-derivations and should be
    # removed once the issue has been resolved.
    || components != [ ] && match "[0-9a-z]{52}" (head components) != null;

in
# No rec! Add dependencies on this file at the top.
{

  append =
    # The absolute path to append to
    path:
    # The subpath string to append
    subpath:
    assert assertMsg (isPath path)
      "lib.path.append: The first argument is of type ${builtins.typeOf path}, but a path was expected";
    assert assertMsg (isValid subpath) ''
      lib.path.append: Second argument is not a valid subpath string:
          ${subpathInvalidReason subpath}'';
    path + ("/" + subpath);

  hasPrefix =
    path1:
    assert assertMsg (isPath path1)
      "lib.path.hasPrefix: First argument is of type ${typeOf path1}, but a path was expected";
    let
      path1Deconstructed = deconstructPath path1;
    in
    path2:
    assert assertMsg (isPath path2)
      "lib.path.hasPrefix: Second argument is of type ${typeOf path2}, but a path was expected";
    let
      path2Deconstructed = deconstructPath path2;
    in
    assert assertMsg (path1Deconstructed.root == path2Deconstructed.root) ''
      lib.path.hasPrefix: Filesystem roots must be the same for both paths, but paths with different roots were given:
          first argument: "${toString path1}" with root "${toString path1Deconstructed.root}"
          second argument: "${toString path2}" with root "${toString path2Deconstructed.root}"'';
    take (length path1Deconstructed.components) path2Deconstructed.components
    == path1Deconstructed.components;

  removePrefix =
    path1:
    assert assertMsg (isPath path1)
      "lib.path.removePrefix: First argument is of type ${typeOf path1}, but a path was expected.";
    let
      path1Deconstructed = deconstructPath path1;
      path1Length = length path1Deconstructed.components;
    in
    path2:
    assert assertMsg (isPath path2)
      "lib.path.removePrefix: Second argument is of type ${typeOf path2}, but a path was expected.";
    let
      path2Deconstructed = deconstructPath path2;
      success = take path1Length path2Deconstructed.components == path1Deconstructed.components;
      components =
        if success then
          drop path1Length path2Deconstructed.components
        else
          throw ''lib.path.removePrefix: The first path argument "${toString path1}" is not a component-wise prefix of the second path argument "${toString path2}".'';
    in
    assert assertMsg (path1Deconstructed.root == path2Deconstructed.root) ''
      lib.path.removePrefix: Filesystem roots must be the same for both paths, but paths with different roots were given:
          first argument: "${toString path1}" with root "${toString path1Deconstructed.root}"
          second argument: "${toString path2}" with root "${toString path2Deconstructed.root}"'';
    joinRelPath components;

  splitRoot =
    # The path to split the root off of
    path:
    assert assertMsg (isPath path)
      "lib.path.splitRoot: Argument is of type ${typeOf path}, but a path was expected";
    let
      deconstructed = deconstructPath path;
    in
    {
      root = deconstructed.root;
      subpath = joinRelPath deconstructed.components;
    };

  hasStorePathPrefix =
    path:
    let
      deconstructed = deconstructPath path;
    in
    assert assertMsg (isPath path)
      "lib.path.hasStorePathPrefix: Argument is of type ${typeOf path}, but a path was expected";
    assert assertMsg
      # This function likely breaks or needs adjustment if used with other filesystem roots, if they ever get implemented.
      # Let's try to error nicely in such a case, though it's unclear how an implementation would work even and whether this could be detected.
      # See also https://github.com/NixOS/nix/pull/6530#discussion_r1422843117
      (deconstructed.root == /. && toString deconstructed.root == "/")
      "lib.path.hasStorePathPrefix: Argument has a filesystem root (${toString deconstructed.root}) that's not /, which is currently not supported.";
    componentsHaveStorePathPrefix deconstructed.components;

  subpath.isValid =
    # The value to check
    value: subpathInvalidReason value == null;

  subpath.join =
    # The list of subpaths to join together
    subpaths:
    # Fast in case all paths are valid
    if all isValid subpaths then
      joinRelPath (concatMap splitRelPath subpaths)
    else
      # Otherwise we take our time to gather more info for a better error message
      # Strictly go through each path, throwing on the first invalid one
      # Tracks the list index in the fold accumulator
      foldl' (
        i: path:
        if isValid path then
          i + 1
        else
          throw ''
            lib.path.subpath.join: Element at index ${toString i} is not a valid subpath string:
                ${subpathInvalidReason path}''
      ) 0 subpaths;

  subpath.components =
    # The subpath string to split into components
    subpath:
    assert assertMsg (isValid subpath) ''
      lib.path.subpath.components: Argument is not a valid subpath string:
          ${subpathInvalidReason subpath}'';
    splitRelPath subpath;

  subpath.normalise =
    # The subpath string to normalise
    subpath:
    assert assertMsg (isValid subpath) ''
      lib.path.subpath.normalise: Argument is not a valid subpath string:
          ${subpathInvalidReason subpath}'';
    joinRelPath (splitRelPath subpath);

}

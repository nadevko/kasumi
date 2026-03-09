{ lib }:
let

  inherit (builtins) length;

  inherit (lib.trivial) warnIf;

  asciiTable = import ./ascii-to-num.nix;

in

rec {
  trim = trimWith {
    start = true;
    end = true;
  };
  trimWith =
    {
      start ? false,
      end ? false,
    }:
    let
      chars = " \t\r\n";
      regex =
        if start && end then
          "[${chars}]*(.*[^${chars}])[${chars}]*"
        else if start then
          "[${chars}]*(.*)"
        else if end then
          "(.*[^${chars}])[${chars}]*"
        else
          "(.*)";
    in
    s:
    let
      res = match regex s;
    in
    optionalString (res != null) (head res);

  makeSearchPath =
    subDir: paths: concatStringsSep ":" (map (path: path + "/" + subDir) (filter (x: x != null) paths));

  makeSearchPathOutput =
    output: subDir: pkgs:
    makeSearchPath subDir (map (lib.getOutput output) pkgs);

  makeLibraryPath = makeSearchPathOutput "lib" "lib";

  makeIncludePath = makeSearchPathOutput "dev" "include";

  makeBinPath = makeSearchPathOutput "bin" "bin";

  normalizePath =
    s:
    warnIf (isPath s)
      ''
        lib.strings.normalizePath: The argument (${toString s}) is a path value, but only strings are supported.
            Path values are always normalised in Nix, so there's no need to call this function on them.
            This function also copies the path to the Nix store and returns the store path, the same as "''${path}" will, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.''
      (
        builtins.foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x + y) "" (stringToCharacters s)
      );

  hasInfix =
    infix: content:
    # Before 23.05, paths would be copied to the store before converting them
    # to strings and comparing. This was surprising and confusing.
    warnIf (isPath infix)
      ''
        lib.strings.hasInfix: The first argument (${toString infix}) is a path value, but only strings are supported.
            There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
            This function also copies the path to the Nix store, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.''
      (builtins.match ".*${escapeRegex infix}.*" "${content}" != null);

  escape = list: replaceStrings list (map (c: "\\${c}") list);

  escapeC =
    list:
    replaceStrings list (
      map (c: "\\x${fixedWidthString 2 "0" (toLower (lib.toHexString (charToInt c)))}") list
    );

  escapeURL =
    let
      unreserved = import ./rfc3986-unreserved.nix;
      toEscape = removeAttrs asciiTable unreserved;
    in
    replaceStrings (builtins.attrNames toEscape) (
      lib.mapAttrsToList (_: c: "%${fixedWidthString 2 "0" (lib.toHexString c)}") toEscape
    );

  escapeShellArg =
    arg:
    let
      string = toString arg;
    in
    if match "[[:alnum:],._+:@%/-]+" string == null then
      "'${replaceString "'" "'\\''" string}'"
    else
      string;

  escapeShellArgs = concatMapStringsSep " " escapeShellArg;

  isValidPosixName = name: match "[a-zA-Z_][a-zA-Z0-9_]*" name != null;

  toShellVar =
    name: value:
    lib.throwIfNot (isValidPosixName name) "toShellVar: ${name} is not a valid shell variable name" (
      if isAttrs value && !isStringLike value then
        "declare -A ${name}=(${
          concatStringsSep " " (lib.mapAttrsToList (n: v: "[${escapeShellArg n}]=${escapeShellArg v}") value)
        })"
      else if isList value then
        "declare -a ${name}=(${escapeShellArgs value})"
      else
        "${name}=${escapeShellArg value}"
    );

  toShellVars = vars: concatStringsSep "\n" (lib.mapAttrsToList toShellVar vars);

  escapeNixString = s: escape [ "$" ] (toJSON s);

  escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");

  escapeNixIdentifier =
    let
      # see https://nix.dev/manual/nix/2.26/language/identifiers#keywords
      nixKeywords = [
        "assert"
        "else"
        "if"
        "in"
        "inherit"
        "let"
        "or"
        "rec"
        "then"
        "with"
      ];
    in
    s:
    # Regex from https://github.com/NixOS/nix/blob/d048577909e383439c2549e849c5c2f2016c997e/src/libexpr/lexer.l#L91
    if (match "[a-zA-Z_][a-zA-Z0-9_'-]*" s != null) && (!lib.elem s nixKeywords) then
      s
    else
      escapeNixString s;

  escapeXML =
    builtins.replaceStrings
      [ "\"" "'" "<" ">" "&" ]
      [ "&quot;" "&apos;" "&lt;" "&gt;" "&amp;" ];

  lowerChars = stringToCharacters "abcdefghijklmnopqrstuvwxyz";
  upperChars = stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  toLower = replaceStrings upperChars lowerChars;

  toUpper = replaceStrings lowerChars upperChars;

  toSentenceCase =
    str:
    lib.throwIfNot (isString str)
      "toSentenceCase does only accepts string values, but got ${typeOf str}"
      (
        let
          firstChar = substring 0 1 str;
          rest = substring 1 (stringLength str) str;
        in
        addContextFrom str (toUpper firstChar + toLower rest)
      );

  toCamelCase =
    str:
    lib.throwIfNot (isString str) "toCamelCase does only accepts string values, but got ${typeOf str}" (
      let
        separators = splitStringBy (
          prev: curr:
          elem curr [
            "-"
            "_"
            " "
          ]
        ) false str;

        parts = lib.flatten (
          map (splitStringBy (
            prev: curr: match "[a-z]" prev != null && match "[A-Z]" curr != null
          ) true) separators
        );

        first = if length parts > 0 then toLower (head parts) else "";
        rest = if length parts > 1 then map toSentenceCase (tail parts) else [ ];
      in
      concatStrings (map (addContextFrom str) ([ first ] ++ rest))
    );

  addContextFrom = src: target: substring 0 0 src + target;

  splitString =
    sep: s:
    let
      splits = builtins.filter builtins.isString (
        builtins.split (escapeRegex (toString sep)) (toString s)
      );
    in
    map (addContextFrom s) splits;

  splitStringBy =
    predicate: keepSplit: str:
    let
      len = stringLength str;

      # Helper function that processes the string character by character
      go =
        pos: currentPart: result:
        # Base case: reached end of string
        if pos == len then
          result ++ [ currentPart ]
        else
          let
            currChar = substring pos 1 str;
            prevChar = if pos > 0 then substring (pos - 1) 1 str else "";
            isSplit = predicate prevChar currChar;
          in
          if isSplit then
            # Split here - add current part to results and start a new one
            let
              newResult = result ++ [ currentPart ];
              newCurrentPart = if keepSplit then currChar else "";
            in
            go (pos + 1) newCurrentPart newResult
          else
            # Keep building current part
            go (pos + 1) (currentPart + currChar) result;
    in
    if len == 0 then [ (addContextFrom str "") ] else map (addContextFrom str) (go 0 "" [ ]);

  removePrefix =
    prefix: str:
    # Before 23.05, paths would be copied to the store before converting them
    # to strings and comparing. This was surprising and confusing.
    warnIf (isPath prefix)
      ''
        lib.strings.removePrefix: The first argument (${toString prefix}) is a path value, but only strings are supported.
            There is almost certainly a bug in the calling code, since this function never removes any prefix in such a case.
            This function also copies the path to the Nix store, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.''
      (
        let
          preLen = stringLength prefix;
        in
        if substring 0 preLen str == prefix then
          # -1 will take the string until the end
          substring preLen (-1) str
        else
          str
      );

  removeSuffix =
    suffix: str:
    # Before 23.05, paths would be copied to the store before converting them
    # to strings and comparing. This was surprising and confusing.
    warnIf (isPath suffix)
      ''
        lib.strings.removeSuffix: The first argument (${toString suffix}) is a path value, but only strings are supported.
            There is almost certainly a bug in the calling code, since this function never removes any suffix in such a case.
            This function also copies the path to the Nix store, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.''
      (
        let
          sufLen = stringLength suffix;
          sLen = stringLength str;
        in
        if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then
          substring 0 (sLen - sufLen) str
        else
          str
      );

  versionOlder = v1: v2: compareVersions v2 v1 == 1;

  versionAtLeast = v1: v2: !versionOlder v1 v2;

  getName =
    let
      parse = drv: (parseDrvName drv).name;
    in
    x: if isString x then parse x else x.pname or (parse x.name);

  getVersion =
    let
      parse = drv: (parseDrvName drv).version;
    in
    x: if isString x then parse x else x.version or (parse x.name);

  nameFromURL =
    url: sep:
    let
      components = splitString "/" url;
      filename = lib.last components;
      name = head (splitString sep filename);
    in
    assert name != filename;
    name;

  cmakeOptionType =
    let
      types = [
        "BOOL"
        "FILEPATH"
        "PATH"
        "STRING"
        "INTERNAL"
        "LIST"
      ];
    in
    type: feature: value:
    assert (elem (toUpper type) types);
    assert (isString feature);
    assert (isString value);
    "-D${feature}:${toUpper type}=${value}";

  cmakeBool =
    condition: flag:
    assert (lib.isString condition);
    assert (lib.isBool flag);
    cmakeOptionType "bool" condition (lib.toUpper (lib.boolToString flag));

  cmakeFeature =
    feature: value:
    assert (lib.isString feature);
    assert (lib.isString value);
    cmakeOptionType "string" feature value;

  mesonOption =
    feature: value:
    assert (lib.isString feature);
    assert (lib.isString value);
    "-D${feature}=${value}";

  mesonBool =
    condition: flag:
    assert (lib.isString condition);
    assert (lib.isBool flag);
    mesonOption condition (lib.boolToString flag);

  mesonEnable =
    feature: flag:
    assert (lib.isString feature);
    assert (lib.isBool flag);
    mesonOption feature (if flag then "enabled" else "disabled");

  enableFeature =
    flag: feature:
    assert lib.isBool flag;
    assert lib.isString feature; # e.g. passing openssl instead of "openssl"
    "--${if flag then "enable" else "disable"}-${feature}";

  enableFeatureAs =
    flag: feature: value:
    enableFeature flag feature + optionalString flag "=${value}";

  withFeature =
    flag: feature:
    assert isString feature; # e.g. passing openssl instead of "openssl"
    "--${if flag then "with" else "without"}-${feature}";

  withFeatureAs =
    flag: feature: value:
    withFeature flag feature + optionalString flag "=${value}";

  fixedWidthString =
    width: filler: str:
    let
      strw = lib.stringLength str;
      reqWidth = width - (lib.stringLength filler);
    in
    assert lib.assertMsg (strw <= width)
      "fixedWidthString: requested string length (${toString width}) must not be shorter than actual length (${toString strw})";
    if strw == width then str else filler + fixedWidthString reqWidth filler str;

  fixedWidthNumber = width: n: fixedWidthString width "0" (toString n);

  floatToString =
    float:
    let
      result = toString float;
      precise = float == fromJSON result;
    in
    lib.warnIf (!precise) "Imprecise conversion from float to string ${result}" result;

  isConvertibleWithToString =
    let
      types = [
        "null"
        "int"
        "float"
        "bool"
      ];
    in
    x: isStringLike x || elem (typeOf x) types || (isList x && lib.all isConvertibleWithToString x);

  isStringLike = x: isString x || isPath x || x ? outPath || x ? __toString;

  isStorePath =
    x:
    if isStringLike x then
      let
        str = toString x;
      in
      substring 0 1 str == "/"
      && (
        dirOf str == storeDir
        # Match content‐addressed derivations, which _currently_ do not have a
        # store directory prefix.
        # This is a workaround for https://github.com/NixOS/nix/issues/12361
        # which was needed during the experimental phase of ca-derivations and
        # should be removed once the issue has been resolved.
        || builtins.match "/[0-9a-z]{52}" str != null
      )
    else
      false;

  toInt =
    let
      matchStripInput = match "[[:space:]]*(-?[[:digit:]]+)[[:space:]]*";
      matchLeadingZero = match "0[[:digit:]]+";
    in
    str:
    let
      # RegEx: Match any leading whitespace, possibly a '-', one or more digits,
      # and finally match any trailing whitespace.
      strippedInput = matchStripInput str;

      # RegEx: Match a leading '0' then one or more digits.
      isLeadingZero = matchLeadingZero (head strippedInput) == [ ];

      # Attempt to parse input
      parsedInput = fromJSON (head strippedInput);

      generalError = "toInt: Could not convert ${escapeNixString str} to int.";

    in
    # Error on presence of non digit characters.
    if strippedInput == null then
      throw generalError
    # Error on presence of leading zero/octal ambiguity.
    else if isLeadingZero then
      throw "toInt: Ambiguity in interpretation of ${escapeNixString str} between octal and zero padded integer."
    # Error if parse function fails.
    else if !isInt parsedInput then
      throw generalError
    # Return result.
    else
      parsedInput;

  toIntBase10 =
    let
      matchStripInput = match "[[:space:]]*0*(-?[[:digit:]]+)[[:space:]]*";
      matchZero = match "0+";
    in
    str:
    let
      # RegEx: Match any leading whitespace, then match any zero padding,
      # capture possibly a '-' followed by one or more digits,
      # and finally match any trailing whitespace.
      strippedInput = matchStripInput str;

      # RegEx: Match at least one '0'.
      isZero = matchZero (head strippedInput) == [ ];

      # Attempt to parse input
      parsedInput = fromJSON (head strippedInput);

      generalError = "toIntBase10: Could not convert ${escapeNixString str} to int.";

    in
    # Error on presence of non digit characters.
    if strippedInput == null then
      throw generalError
    # In the special case zero-padded zero (00000), return early.
    else if isZero then
      0
    # Error if parse function fails.
    else if !isInt parsedInput then
      throw generalError
    # Return result.
    else
      parsedInput;

  fileContents = file: removeSuffix "\n" (readFile file);

  sanitizeDerivationName =
    let
      okRegex = match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*";
    in
    string:
    # First detect the common case of already valid strings, to speed those up
    if stringLength string <= 207 && okRegex string != null then
      unsafeDiscardStringContext string
    else
      lib.pipe string [
        # Get rid of string context. This is safe under the assumption that the
        # resulting string is only used as a derivation name
        unsafeDiscardStringContext
        # Strip all leading "."
        (x: elemAt (match "\\.*(.*)" x) 0)
        # Split out all invalid characters
        # https://github.com/NixOS/nix/blob/2.3.2/src/libstore/store-api.cc#L85-L112
        # https://github.com/NixOS/nix/blob/2242be83c61788b9c0736a92bb0b5c7bbfc40803/nix-rust/src/store/path.rs#L100-L125
        (split "[^[:alnum:]+._?=-]+")
        # Replace invalid character ranges with a "-"
        (concatMapStrings (s: if lib.isList s then "-" else s))
        # Limit to 211 characters (minus 4 chars for ".drv")
        (x: substring (lib.max (stringLength x - 207) 0) (-1) x)
        # If the result is empty, replace it with "unknown"
        (x: if stringLength x == 0 then "unknown" else x)
      ];
}

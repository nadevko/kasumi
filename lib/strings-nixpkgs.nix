rec {
  makeSearchPath =
    subDir: paths: concatStringsSep ":" (map (path: path + "/" + subDir) (filter (x: x != null) paths));

  makeSearchPathOutput =
    output: subDir: pkgs:
    makeSearchPath subDir (map (lib.getOutput output) pkgs);

  makeLibraryPath = makeSearchPathOutput "lib" "lib";

  makeIncludePath = makeSearchPathOutput "dev" "include";

  makeBinPath = makeSearchPathOutput "bin" "bin";

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
}

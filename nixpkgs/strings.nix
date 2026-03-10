{ lib }:
let

  inherit (builtins) length;

  inherit (lib.trivial) warnIf;

  asciiTable = import ./ascii-table.nix;

in

rec {

  inherit (builtins)
    compareVersions
    elem
    elemAt
    filter
    fromJSON
    genList
    head
    isInt
    isList
    isAttrs
    isPath
    isString
    match
    parseDrvName
    readFile
    replaceStrings
    split
    storeDir
    stringLength
    substring
    tail
    toJSON
    typeOf
    unsafeDiscardStringContext
    appendContext
    ;

  join = builtins.concatStringsSep;

  concatStrings = builtins.concatStringsSep "";

  concatMapStrings = f: list: concatStrings (map f list);

  concatImapStrings = f: list: concatStrings (lib.imap1 f list);

  intersperse =
    separator: list:
    if list == [ ] || length list == 1 then
      list
    else
      tail (
        lib.concatMap (x: [
          separator
          x
        ]) list
      );

  concatStringsSep = builtins.concatStringsSep;

  concatMapStringsSep =
    sep: f: list:
    concatStringsSep sep (map f list);

  concatImapStringsSep =
    sep: f: list:
    concatStringsSep sep (lib.imap1 f list);

  concatMapAttrsStringSep =
    sep: f: attrs:
    concatStringsSep sep (lib.attrValues (lib.mapAttrs f attrs));

  concatLines = concatMapStrings (s: s + "\n");

  replaceString = from: to: replaceStrings [ from ] [ to ];

  replicate = n: s: concatStrings (lib.lists.replicate n s);

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
      # Define our own whitespace character class instead of using
      # `[:space:]`, which is not well-defined.
      chars = " \t\r\n";

      # To match up until trailing whitespace, we need to capture a
      # group that ends with a non-whitespace character.
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
      # If the string was empty or entirely whitespace,
      # then the regex may not match and `res` will be `null`.
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

  optionalString = cond: string: if cond then string else "";

  hasPrefix =
    pref: str:
    # Before 23.05, paths would be copied to the store before converting them
    # to strings and comparing. This was surprising and confusing.
    warnIf (isPath pref)
      ''
        lib.strings.hasPrefix: The first argument (${toString pref}) is a path value, but only strings are supported.
            There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
            This function also copies the path to the Nix store, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.
            You might want to use `lib.path.hasPrefix` instead, which correctly supports paths.''
      (substring 0 (stringLength pref) str == pref);

  hasSuffix =
    suffix: content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in
    # Before 23.05, paths would be copied to the store before converting them
    # to strings and comparing. This was surprising and confusing.
    warnIf (isPath suffix)
      ''
        lib.strings.hasSuffix: The first argument (${toString suffix}) is a path value, but only strings are supported.
            There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
            This function also copies the path to the Nix store, which may not be what you want.
            This behavior is deprecated and will throw an error in the future.''
      (lenContent >= lenSuffix && substring (lenContent - lenSuffix) lenContent content == suffix);

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

  stringToCharacters = s: genList (p: substring p 1 s) (stringLength s);

  stringAsChars =
    # Function to map over each individual character
    f:
    # Input string
    s:
    concatStrings (map f (stringToCharacters s));

  charToInt = c: builtins.getAttr c asciiTable;

  escape = list: replaceStrings list (map (c: "\\${c}") list);

  escapeC =
    list:
    replaceStrings list (
      map (c: "\\x${fixedWidthString 2 "0" (toLower (lib.toHexString (charToInt c)))}") list
    );

  escapeURL =
    let
      unreserved = [
        "A"
        "B"
        "C"
        "D"
        "E"
        "F"
        "G"
        "H"
        "I"
        "J"
        "K"
        "L"
        "M"
        "N"
        "O"
        "P"
        "Q"
        "R"
        "S"
        "T"
        "U"
        "V"
        "W"
        "X"
        "Y"
        "Z"
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
        "g"
        "h"
        "i"
        "j"
        "k"
        "l"
        "m"
        "n"
        "o"
        "p"
        "q"
        "r"
        "s"
        "t"
        "u"
        "v"
        "w"
        "x"
        "y"
        "z"
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
        "-"
        "_"
        "."
        "~"
      ];
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

  # Case conversion utilities.
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

  levenshtein =
    a: b:
    let
      # Two dimensional array with dimensions (stringLength a + 1, stringLength b + 1)
      arr = lib.genList (i: lib.genList (j: dist i j) (stringLength b + 1)) (stringLength a + 1);
      d = x: y: lib.elemAt (lib.elemAt arr x) y;
      dist =
        i: j:
        let
          c = if substring (i - 1) 1 a == substring (j - 1) 1 b then 0 else 1;
        in
        if j == 0 then
          i
        else if i == 0 then
          j
        else
          lib.min (lib.min (d (i - 1) j + 1) (d i (j - 1) + 1)) (d (i - 1) (j - 1) + c);
    in
    d (stringLength a) (stringLength b);

  commonPrefixLength =
    a: b:
    let
      m = lib.min (stringLength a) (stringLength b);
      go =
        i:
        if i >= m then
          m
        else if substring i 1 a == substring i 1 b then
          go (i + 1)
        else
          i;
    in
    go 0;

  commonSuffixLength =
    a: b:
    let
      m = lib.min (stringLength a) (stringLength b);
      go =
        i:
        if i >= m then
          m
        else if substring (stringLength a - i - 1) 1 a == substring (stringLength b - i - 1) 1 b then
          go (i + 1)
        else
          i;
    in
    go 0;

  levenshteinAtMost =
    let
      infixDifferAtMost1 = x: y: stringLength x <= 1 && stringLength y <= 1;

      # This function takes two strings stripped by their common pre and suffix,
      # and returns whether they differ by at most two by Levenshtein distance.
      # Because of this stripping, if they do indeed differ by at most two edits,
      # we know that those edits were (if at all) done at the start or the end,
      # while the middle has to have stayed the same. This fact is used in the
      # implementation.
      infixDifferAtMost2 =
        x: y:
        let
          xlen = stringLength x;
          ylen = stringLength y;
          # This function is only called with |x| >= |y| and |x| - |y| <= 2, so
          # diff is one of 0, 1 or 2
          diff = xlen - ylen;

          # Infix of x and y, stripped by the left and right most character
          xinfix = substring 1 (xlen - 2) x;
          yinfix = substring 1 (ylen - 2) y;

          # x and y but a character deleted at the left or right
          xdelr = substring 0 (xlen - 1) x;
          xdell = substring 1 (xlen - 1) x;
          ydelr = substring 0 (ylen - 1) y;
          ydell = substring 1 (ylen - 1) y;
        in
        # A length difference of 2 can only be gotten with 2 delete edits,
        # which have to have happened at the start and end of x
        # Example: "abcdef" -> "bcde"
        if diff == 2 then
          xinfix == y
        # A length difference of 1 can only be gotten with a deletion on the
        # right and a replacement on the left or vice versa.
        # Example: "abcdef" -> "bcdez" or "zbcde"
        else if diff == 1 then
          xinfix == ydelr || xinfix == ydell
        # No length difference can either happen through replacements on both
        # sides, or a deletion on the left and an insertion on the right or
        # vice versa
        # Example: "abcdef" -> "zbcdez" or "bcdefz" or "zabcde"
        else
          xinfix == yinfix || xdelr == ydell || xdell == ydelr;

    in
    k:
    if k <= 0 then
      a: b: a == b
    else
      let
        f =
          a: b:
          let
            alen = stringLength a;
            blen = stringLength b;
            prelen = commonPrefixLength a b;
            suflen = commonSuffixLength a b;
            presuflen = prelen + suflen;
            ainfix = substring prelen (alen - presuflen) a;
            binfix = substring prelen (blen - presuflen) b;
          in
          # Make a be the bigger string
          if alen < blen then
            f b a
          # If a has over k more characters than b, even with k deletes on a, b can't be reached
          else if alen - blen > k then
            false
          else if k == 1 then
            infixDifferAtMost1 ainfix binfix
          else if k == 2 then
            infixDifferAtMost2 ainfix binfix
          else
            levenshtein ainfix binfix <= k;
      in
      f;
}

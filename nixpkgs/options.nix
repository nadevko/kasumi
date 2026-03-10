{ lib }:

let
  inherit (lib)
    all
    collect
    concatLists
    concatMap
    concatMapStringsSep
    filter
    foldl'
    head
    tail
    isAttrs
    isBool
    isDerivation
    isFunction
    isInt
    isList
    isString
    length
    mapAttrs
    optional
    optionals
    take
    ;
  inherit (lib.attrsets) attrByPath optionalAttrs showAttrPath;
  inherit (lib.strings) concatMapStrings concatStringsSep;
  inherit (lib.types) mkOptionType;
  inherit (lib.lists) last toList;
  prioritySuggestion = ''
    Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
  '';
in
rec {

  isOption = lib.isType "option";

  mkOption =
    {
      default ? null,
      defaultText ? null,
      example ? null,
      description ? null,
      relatedPackages ? null,
      type ? null,
      apply ? null,
      internal ? null,
      visible ? null,
      readOnly ? null,
    }@attrs:
    attrs // { _type = "option"; };

  mkEnableOption =
    name:
    mkOption {
      default = false;
      example = true;
      description = "Whether to enable ${name}.";
      type = lib.types.bool;
    };

  mkPackageOption =
    pkgs: name:
    {
      nullable ? false,
      default ? name,
      example ? null,
      extraDescription ? "",
      pkgsText ? "pkgs",
    }:
    let
      name' = if isList name then last name else name;
      default' = toList default;
      defaultText = showAttrPath default';
      defaultValue = attrByPath default' (throw "${defaultText} cannot be found in ${pkgsText}") pkgs;
      defaults =
        if default != null then
          {
            default = defaultValue;
            defaultText = literalExpression "${pkgsText}.${defaultText}";
          }
        else
          optionalAttrs nullable { default = null; };
    in
    mkOption (
      defaults
      // {
        description =
          "The ${name'} package to use." + (if extraDescription == "" then "" else " ") + extraDescription;
        type = with lib.types; (if nullable then nullOr else lib.id) package;
      }
      // optionalAttrs (example != null) {
        example = literalExpression (
          if isList example then "${pkgsText}.${showAttrPath example}" else example
        );
      }
    );

  mkSinkUndeclaredOptions =
    attrs:
    mkOption (
      {
        internal = true;
        visible = false;
        default = false;
        description = "Sink for option definitions.";
        type = mkOptionType {
          name = "sink";
          check = x: true;
          merge = loc: defs: false;
        };
        apply = x: throw "Option value is not readable because the option is not declared.";
      }
      // attrs
    );

  mergeDefaultOption =
    loc: defs:
    let
      list = getValues defs;
    in
    if length list == 1 then
      head list
    else if all isFunction list then
      x: mergeDefaultOption loc (map (f: f x) list)
    else if all isList list then
      concatLists list
    else if all isAttrs list then
      foldl' lib.mergeAttrs { } list
    else if all isBool list then
      foldl' lib."or" false list
    else if all isString list then
      lib.concatStrings list
    else if all isInt list && all (x: x == head list) list then
      head list
    else
      throw "Cannot merge definitions of `${showOption loc}'. Definition values:${showDefs defs}";

  mergeOneOption = mergeUniqueOption { message = ""; };

  mergeUniqueOption =
    args@{
      message,
      # WARNING: the default merge function assumes that the definition is a valid (option) value. You MUST pass a merge function if the return value needs to be
      #   - type checked beyond what .check does (which should be very little; only on the value head; not attribute values, etc)
      #   - if you want attribute values to be checked, or list items
      #   - if you want coercedTo-like behavior to work
      merge ? loc: defs: (head defs).value,
    }:
    loc: defs:
    if length defs == 1 then
      merge loc defs
    else
      assert length defs > 1;
      throw "The option `${showOption loc}' is defined multiple times while it's expected to be unique.\n${message}\nDefinition values:${showDefs defs}\n${prioritySuggestion}";

  mergeEqualOption =
    loc: defs:
    if defs == [ ] then
      abort "This case should never happen."
    # Returns early if we only have one element
    # This also makes it work for functions, because the foldl' below would try
    # to compare the first element with itself, which is false for functions
    else if length defs == 1 then
      (head defs).value
    else
      (foldl' (
        first: def:
        if def.value != first.value then
          throw "The option `${showOption loc}' has conflicting definition values:${
            showDefs [
              first
              def
            ]
          }\n${prioritySuggestion}"
        else
          first
      ) (head defs) (tail defs)).value;

  getValues = map (x: x.value);

  getFiles = map (x: x.file);

  # Generate documentation template from the list of option declaration like
  # the set generated with filterOptionSets.
  optionAttrSetToDocList = optionAttrSetToDocList' [ ];

  optionAttrSetToDocList' =
    _: options:
    concatMap (
      opt:
      let
        name = showOption opt.loc;
        visible = opt.visible or true;
        docOption = {
          loc = opt.loc;
          inherit name;
          description = opt.description or null;
          declarations = filter (x: x != unknownModule) opt.declarations;
          internal = opt.internal or false;
          visible = if isBool visible then visible else visible == "shallow";
          readOnly = opt.readOnly or false;
          type = opt.type.description or "unspecified";
        }
        // optionalAttrs (opt ? example) {
          example = builtins.addErrorContext "while evaluating the example of option `${name}`" (
            renderOptionValue opt.example
          );
        }
        // optionalAttrs (opt ? defaultText || opt ? default) {
          default = builtins.addErrorContext "while evaluating the ${
            if opt ? defaultText then "defaultText" else "default value"
          } of option `${name}`" (renderOptionValue (opt.defaultText or opt.default));
        }
        // optionalAttrs (opt ? relatedPackages && opt.relatedPackages != null) {
          inherit (opt) relatedPackages;
        };

        subOptions =
          let
            ss = opt.type.getSubOptions opt.loc;
          in
          if ss != { } then optionAttrSetToDocList' opt.loc ss else [ ];
        subOptionsVisible = if isBool visible then visible else visible == "transparent";
      in
      # To find infinite recursion in NixOS option docs:
      # builtins.trace opt.loc
      [ docOption ] ++ optionals subOptionsVisible subOptions
    ) (collect isOption options);

  scrubOptionValue =
    x:
    if isDerivation x then
      {
        type = "derivation";
        drvPath = x.name;
        outPath = x.name;
        name = x.name;
      }
    else if isList x then
      map scrubOptionValue x
    else if isAttrs x then
      mapAttrs (n: v: scrubOptionValue v) (removeAttrs x [ "_args" ])
    else
      x;

  renderOptionValue =
    v:
    if v ? _type && v ? text then
      v
    else
      literalExpression (
        lib.generators.toPretty {
          multiline = true;
          allowPrettyValues = true;
        } v
      );

  literalExpression =
    text:
    if !isString text then
      throw "literalExpression expects a string."
    else
      {
        _type = "literalExpression";
        inherit text;
      };

  literalCode =
    languageTag: text:
    lib.literalMD ''
      ```${languageTag}
      ${text}
      ```
    '';

  literalMD =
    text:
    if !isString text then
      throw "literalMD expects a string."
    else
      {
        _type = "literalMD";
        inherit text;
      };

  # Helper functions.

  showOption =
    parts:
    let
      # If the part is a named placeholder of the form "<...>" don't escape it.
      # It may cause misleading escaping if somebody uses literally "<...>" in their option names.
      # This is the trade-off to allow for placeholders in option names.
      isNamedPlaceholder = builtins.match "<(.*)>";
      escapeOptionPart =
        part:
        if part == "*" || isNamedPlaceholder part != null then
          part
        else
          lib.strings.escapeNixIdentifier part;
    in
    (concatStringsSep ".") (map escapeOptionPart parts);
  showFiles = files: concatStringsSep " and " (map (f: "`${f}'") files);

  showDefs =
    defs:
    concatMapStrings (
      def:
      let
        # Pretty print the value for display, if successful
        prettyEval = builtins.tryEval (
          lib.generators.toPretty { } (
            lib.generators.withRecursion {
              depthLimit = 10;
              throwOnDepthLimit = false;
            } def.value
          )
        );
        # Split it into its lines
        lines = filter (v: !isList v) (builtins.split "\n" prettyEval.value);
        # Only display the first 5 lines, and indent them for better visibility
        value = concatStringsSep "\n    " (take 5 lines ++ optional (length lines > 5) "...");
        result =
          # Don't print any value if evaluating the value strictly fails
          if !prettyEval.success then
            ""
          # Put it on a new line if it consists of multiple
          else if length lines > 1 then
            ":\n    " + value
          else
            ": " + value;
      in
      "\n- In `${def.file}'${result}"
    ) defs;

  showOptionWithDefLocs = opt: ''
    ${showOption opt.loc}, with values defined in:
    ${concatMapStringsSep "\n" (defFile: "  - ${defFile}") opt.files}
  '';

  unknownModule = "<unknown-file>";

}

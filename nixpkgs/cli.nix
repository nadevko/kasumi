{ lib }:

{

  toGNUCommandLineShell =
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2511)
      "lib.cli.toGNUCommandLineShell is deprecated, please use lib.cli.toCommandLineShell or lib.cli.toCommandLineShellGNU instead."
      (options: attrs: lib.escapeShellArgs (lib.cli.toGNUCommandLine options attrs));

  toGNUCommandLine =
    lib.warnIf (lib.oldestSupportedReleaseIsAtLeast 2511)
      "lib.cli.toGNUCommandLine is deprecated, please use lib.cli.toCommandLine or lib.cli.toCommandLineShellGNU instead."
      (
        {
          mkOptionName ? k: if builtins.stringLength k == 1 then "-${k}" else "--${k}",

          mkBool ? k: v: lib.optional v (mkOptionName k),

          mkList ? k: v: lib.concatMap (mkOption k) v,

          mkOption ?
            k: v:
            if v == null then
              [ ]
            else if optionValueSeparator == null then
              [
                (mkOptionName k)
                (lib.generators.mkValueStringDefault { } v)
              ]
            else
              [ "${mkOptionName k}${optionValueSeparator}${lib.generators.mkValueStringDefault { } v}" ],

          optionValueSeparator ? null,
        }:
        options:
        let
          render =
            k: v:
            if builtins.isBool v then
              mkBool k v
            else if builtins.isList v then
              mkList k v
            else
              mkOption k v;

        in
        builtins.concatLists (lib.mapAttrsToList render options)
      );

  toCommandLineShellGNU =
    options: attrs: lib.escapeShellArgs (lib.cli.toCommandLineGNU options attrs);

  toCommandLineGNU =
    {
      isLong ? optionName: builtins.stringLength optionName > 1,
      explicitBool ? false,
      formatArg ? lib.generators.mkValueStringDefault { },
    }:
    let
      optionFormat = optionName: {
        option = if isLong optionName then "--${optionName}" else "-${optionName}";
        sep = if isLong optionName then "=" else "";
        inherit explicitBool formatArg;
      };
    in
    lib.cli.toCommandLine optionFormat;

  toCommandLineShell =
    optionFormat: attrs: lib.escapeShellArgs (lib.cli.toCommandLine optionFormat attrs);

  toCommandLine =
    optionFormat: attrs:
    let
      handlePair =
        k: v:
        if k == "" then
          lib.throw "lib.cli.toCommandLine only accepts non-empty option names."
        else if builtins.isList v then
          builtins.concatMap (handleOption k) v
        else
          handleOption k v;

      handleOption = k: renderOption (optionFormat k) k;

      renderOption =
        {
          option,
          sep,
          explicitBool,
          formatArg ? lib.generators.mkValueStringDefault { },
        }:
        k: v:
        if v == null || (!explicitBool && v == false) then
          [ ]
        else if !explicitBool && v == true then
          [ option ]
        else
          let
            arg = formatArg v;
          in
          if sep != null then
            [ "${option}${sep}${arg}" ]
          else
            [
              option
              arg
            ];
    in
    builtins.concatLists (lib.mapAttrsToList handlePair attrs);
}

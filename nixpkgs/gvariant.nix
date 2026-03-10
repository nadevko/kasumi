# This file is based on https://github.com/nix-community/home-manager
# Copyright (c) 2017-2022 Home Manager contributors
{ lib }:

let
  inherit (lib)
    concatMapStringsSep
    concatStrings
    escape
    head
    replaceString
    ;

  mkPrimitive = t: v: {
    _type = "gvariant";
    type = t;
    value = v;
    __toString = self: "@${self.type} ${toString self.value}"; # https://docs.gtk.org/glib/gvariant-text.html
  };

  type = {
    arrayOf = t: "a${t}";
    maybeOf = t: "m${t}";
    tupleOf = ts: "(${concatStrings ts})";
    dictionaryEntryOf = nameType: valueType: "{${nameType}${valueType}}";
    string = "s";
    boolean = "b";
    uchar = "y";
    int16 = "n";
    uint16 = "q";
    int32 = "i";
    uint32 = "u";
    int64 = "x";
    uint64 = "t";
    double = "d";
    variant = "v";
  };

in
rec {

  inherit type;

  isGVariant = v: v._type or "" == "gvariant";

  intConstructors = [
    {
      name = "mkInt32";
      type = type.int32;
      min = -2147483648;
      max = 2147483647;
    }
    {
      name = "mkUint32";
      type = type.uint32;
      min = 0;
      max = 4294967295;
    }
    {
      name = "mkInt64";
      type = type.int64;
      # Nix does not support such large numbers.
      min = null;
      max = null;
    }
    {
      name = "mkUint64";
      type = type.uint64;
      min = 0;
      # Nix does not support such large numbers.
      max = null;
    }
    {
      name = "mkInt16";
      type = type.int16;
      min = -32768;
      max = 32767;
    }
    {
      name = "mkUint16";
      type = type.uint16;
      min = 0;
      max = 65535;
    }
    {
      name = "mkUchar";
      type = type.uchar;
      min = 0;
      max = 255;
    }
  ];

  mkValue =
    v:
    if builtins.isBool v then
      mkBoolean v
    else if builtins.isFloat v then
      mkDouble v
    else if builtins.isString v then
      mkString v
    else if builtins.isList v then
      mkArray v
    else if isGVariant v then
      v
    else if builtins.isInt v then
      let
        validConstructors = builtins.filter (
          { min, max, ... }: (min == null || min <= v) && (max == null || v <= max)
        ) intConstructors;
      in
      throw ''
        The GVariant type for number “${toString v}” is unclear.
        Please wrap the value with one of the following, depending on the value type in GSettings schema:

        ${lib.concatMapStringsSep "\n" (
          { name, type, ... }: "- `lib.gvariant.${name}` for `${type}`"
        ) validConstructors}
      ''
    else if builtins.isAttrs v then
      throw "Cannot construct GVariant value from an attribute set. If you want to construct a dictionary, you will need to create an array containing items constructed with `lib.gvariant.mkDictionaryEntry`."
    else
      throw "The GVariant type of “${builtins.typeOf v}” can't be inferred.";

  mkArray =
    elems:
    let
      vs = map mkValue (lib.throwIf (elems == [ ]) "Please create empty array with mkEmptyArray." elems);
      elemType = lib.throwIfNot (lib.all (t: (head vs).type == t) (
        map (v: v.type) vs
      )) "Elements in a list should have same type." (head vs).type;
    in
    mkPrimitive (type.arrayOf elemType) vs
    // {
      __toString = self: "@${self.type} [${concatMapStringsSep "," toString self.value}]";
    };

  mkEmptyArray =
    elemType: mkPrimitive (type.arrayOf elemType) [ ] // { __toString = self: "@${self.type} []"; };

  mkVariant =
    elem:
    let
      gvarElem = mkValue elem;
    in
    mkPrimitive type.variant gvarElem // { __toString = self: "<${toString self.value}>"; };

  mkDictionaryEntry =
    name: value:
    let
      name' = mkValue name;
      value' = mkValue value;
      dictionaryType = type.dictionaryEntryOf name'.type value'.type;
    in
    mkPrimitive dictionaryType { inherit name value; }
    // {
      __toString = self: "@${self.type} {${name'},${value'}}";
    };

  mkMaybe =
    elemType: elem:
    mkPrimitive (type.maybeOf elemType) elem
    // {
      __toString =
        self: if self.value == null then "@${self.type} nothing" else "just ${toString self.value}";
    };

  mkNothing = elemType: mkMaybe elemType null;

  mkJust =
    elem:
    let
      gvarElem = mkValue elem;
    in
    mkMaybe gvarElem.type gvarElem;

  mkTuple =
    elems:
    let
      gvarElems = map mkValue elems;
      tupleType = type.tupleOf (map (e: e.type) gvarElems);
    in
    mkPrimitive tupleType gvarElems
    // {
      __toString = self: "@${self.type} (${concatMapStringsSep "," toString self.value})";
    };

  mkBoolean =
    v: mkPrimitive type.boolean v // { __toString = self: if self.value then "true" else "false"; };

  mkString =
    v:
    let
      sanitize = s: replaceString "\n" "\\n" (escape [ "'" "\\" ] s);
    in
    mkPrimitive type.string v // { __toString = self: "'${sanitize self.value}'"; };

  mkObjectpath =
    v: mkPrimitive type.string v // { __toString = self: "objectpath '${escape [ "'" ] self.value}'"; };

  mkUchar = mkPrimitive type.uchar;

  mkInt16 = mkPrimitive type.int16;

  mkUint16 = mkPrimitive type.uint16;

  mkInt32 = v: mkPrimitive type.int32 v // { __toString = self: toString self.value; };

  mkUint32 = mkPrimitive type.uint32;

  mkInt64 = mkPrimitive type.int64;

  mkUint64 = mkPrimitive type.uint64;

  mkDouble = v: mkPrimitive type.double v // { __toString = self: toString self.value; };
}

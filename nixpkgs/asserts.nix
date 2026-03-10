{ lib }:

let
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) filter;
  inherit (lib.trivial) showWarnings;
in
rec {
  # TODO(Profpatsch): add tests that check stderr
  assertMsg = pred: msg: pred || throw msg;

  assertOneOf =
    name: val: xs:
    assertMsg (lib.elem val xs) "${name} must be one of ${lib.generators.toPretty { } xs}, but is: ${
      lib.generators.toPretty { } val
    }";

  assertEachOneOf =
    name: vals: xs:
    assertMsg (lib.all (val: lib.elem val xs) vals)
      "each element in ${name} must be one of ${lib.generators.toPretty { } xs}, but is: ${
        lib.generators.toPretty { } vals
      }";

  checkAssertWarn =
    assertions: warnings: val:
    let
      failedAssertions = map (x: x.message) (filter (x: !x.assertion) assertions);
    in
    if failedAssertions != [ ] then
      throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else
      showWarnings warnings val;

}

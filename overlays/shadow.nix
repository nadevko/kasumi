final: prev:
let
  inherit (prev.debug) seq;
  inherit (prev.filesystem) readFile;
  inherit (prev.lists) fold';
  inherit (prev.strings) removeSuffix;
in
{
  lists = {
    fold' = op: acc: seq acc <| fold' op acc;
  };
  filesystem = {
    readFile = x: readFile x |> removeSuffix "\n";
  };
}

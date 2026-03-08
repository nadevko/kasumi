final: prev:
let
  inherit (prev.lists) fold';
  inherit (prev.trivial) seq;
in
{
  lists = {
    fold' = op: acc: seq acc <| fold' op acc;
  };
}

final: prev:
let
  inherit (builtins)
    length
    filter
    listToAttrs
    elemAt
    ;

  inherit (prev.lists) take drop;

  inherit (final.trivial) max min;
  inherit (final.attrsets) pair;
in
{
  splitAt =
    x: list:
    let
      len = length list;
      x' = max 0 <| min len (if x < 0 then len + x else x);
    in
    {
      left = take x' list;
      right = drop x' list;
    };

  intersectStrings =
    base: target:
    if target == [ ] then
      [ ]
    else
      let
        index = target |> map (e: pair (toString e) null) |> listToAttrs;
      in
      filter (e: index ? "${toString e}") base;

  subtractStrings =
    minuend: subtrahend:
    if subtrahend == [ ] then
      minuend
    else
      let
        index = subtrahend |> map (e: pair (toString e) null) |> listToAttrs;
      in
      filter (e: !index ? "${toString e}") minuend;

  dfold =
    transform: getInitial: getFinal: itemsList:
    let
      totalItems = length itemsList;
      linkStage =
        previousStage: index:
        if index == totalItems then
          getFinal previousStage
        else
          let
            thisStage = transform previousStage (elemAt itemsList index) nextStage;
            nextStage = linkStage thisStage <| index + 1;
          in
          thisStage;
      initialStage = getInitial firstStage;
      firstStage = linkStage initialStage 0;
    in
    firstStage;
}

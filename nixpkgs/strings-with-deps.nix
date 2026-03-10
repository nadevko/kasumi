{ lib }:

let
  inherit (lib)
    concatMapStringsSep
    head
    isAttrs
    listToAttrs
    tail
    ;
in
rec {

  textClosureList =
    predefined: arg:
    let
      f =
        done: todo:
        if todo == [ ] then
          {
            result = [ ];
            inherit done;
          }
        else
          let
            entry = head todo;
          in
          if isAttrs entry then
            let
              x = f done entry.deps;
              y = f x.done (tail todo);
            in
            {
              result = x.result ++ [ entry.text ] ++ y.result;
              done = y.done;
            }
          else if done ? ${entry} then
            f done (tail todo)
          else
            f (
              done
              // listToAttrs [
                {
                  name = entry;
                  value = 1;
                }
              ]
            ) ([ predefined.${entry} ] ++ tail todo);
    in
    (f { } arg).result;

  textClosureMap =
    f: predefined: names:
    concatMapStringsSep "\n" f (textClosureList predefined names);

  noDepEntry = text: {
    inherit text;
    deps = [ ];
  };
  fullDepEntry = text: deps: { inherit text deps; };
  packEntry = deps: {
    inherit deps;
    text = "";
  };

  stringAfter = deps: text: { inherit text deps; };

}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: let
    lib = inputs.nixpkgs.lib;

    rawdata = builtins.readFile ./input.txt;

    getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

    rows = getRows rawdata;

    instruction = n:
      builtins.filter (x: builtins.stringLength x > 0) (builtins.filter builtins.isString (builtins.split "" (lib.strings.replicate
            n (builtins.head rows))));

    mapData = lib.lists.foldl (nodeList: r: let
      directions = row: map (e: builtins.head e) (builtins.filter builtins.isList (builtins.split "([A-Z]{3})" row));
      getNode = row: builtins.elemAt (directions row) 0;
      getLeft = row: builtins.elemAt (directions row) 1;
      getRight = row: builtins.elemAt (directions row) 2;
    in
      nodeList
      // {
        ${getNode r} = {
          L = getLeft r;
          R = getRight r;
          lastChar = getLastChar (getNode r);
        };
      }) {} (lib.lists.sublist 2 (builtins.length rows) rows);

    getLastChar = s: builtins.head (builtins.elemAt (builtins.filter builtins.isList (builtins.split "([A-Z])" s)) 2);

    getStartingNodes = builtins.filter (x: getLastChar x == "A") (builtins.attrNames mapData);

    solveMap =
      lib.lists.foldl (store: direction:
        if store.node == "ZZZ"
        then store
        else {
          node = mapData.${store.node}.${direction};
          iteration = store.iteration + 1;
        }) {
        node = "AAA";
        iteration = 0;
      }
      (instruction 47);

    streamElemAt = s: i:
      if i == 0
      then s.head
      else streamElemAt s.tail (i - 1);

    getDirection = i: builtins.elemAt (instruction 1) (lib.trivial.mod (i - 1) (builtins.length (instruction 1)));
    nextStep = node: directionCount: {
      head = node;
      tail = nextStep mapData.${node}.${getDirection directionCount} (directionCount + 1);
    };
    searchMap = start: nextStep start 1;

    findZ = f:
      lib.lists.foldl (a: b:
        if getLastChar (streamElemAt f b) == "Z"
        then b
        else if a != 0
        then a
        else 0)
      0
      (lib.lists.range 10000 22000); # very slow but doesn't run out of memory

    solveGhostMap = map (s: findZ (searchMap s)) getStartingNodes;
  in {
    taskA = solveMap;
    taskB = solveGhostMap; # need to calcula the least common multiplier of the results [13019 20221 19667 21883 16343 11911]
    # i couldn't find an LCD algorithm that didn't cause infinite recursion
  };
}

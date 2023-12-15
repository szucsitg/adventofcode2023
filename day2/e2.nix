let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  maxColors = [
    {
      color = "red";
      maxCount = 12;
    }
    {
      color = "green";
      maxCount = 13;
    }
    {
      color = "blue";
      maxCount = 14;
    }
  ];

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  getGameID = row: lib.toInt (lib.lists.last (builtins.split " " (builtins.head (builtins.split ":" row))));

  getSets = row: builtins.filter builtins.isString (builtins.split ";" (lib.lists.last (builtins.split ":" row)));

  getCubes = set: builtins.filter builtins.isString (builtins.split "," set);

  colorCount = color: cubes:
    builtins.foldl' (x: y: x + y) 0 (map (cube:
      if lib.strings.hasSuffix color cube
      then (lib.toInt (builtins.head (builtins.match " ([0-9]+)[ a-z]*" cube)))
      else 0)
    cubes);

  # test = cubes: (map(cube: if lib.strings.hasSuffix color cube then (lib.toInt (builtins.head (builtins.match " ([0-9]+)[ a-z]*" cube))) else 0) cubes);

  isCubePossible = cube:
    builtins.foldl' (x: y: x || y) false (map (elem:
      if lib.strings.hasSuffix elem.color cube
      then (lib.toInt (builtins.head (builtins.match " ([0-9]+)[ a-z]*" cube))) <= elem.maxCount
      else false)
    maxColors);

  isSetPossible = cubes: builtins.foldl' (x: y: x && y) true (map (cube: isCubePossible cube) cubes);

  processSets = map (row: {
    gameID = getGameID row;
    gameSet = map (set: isSetPossible (getCubes set)) (getSets row);
  }) (getRows rawdata);

  cubeDataModel = row:
    map (set: {
      blue = colorCount "blue" (getCubes set);
      green = colorCount "green" (getCubes set);
      red = colorCount "red" (getCubes set);
    }) (getSets row);

  minCubeSize = setData: color:
    builtins.foldl' (x: y:
      if x >= y
      then x
      else y)
    0 (map (set: lib.attrsets.attrByPath [color] 0 set) setData);

  processCubes = map (row: {
    gameID = getGameID row;
    gameSet = cubeDataModel row;
  }) (getRows rawdata);

  minCubeSet =
    map (
      game: [
        (minCubeSize game.gameSet "blue")
        (minCubeSize game.gameSet "green")
        (minCubeSize game.gameSet "red")
      ]
    )
    processCubes;

  sumGameIDs = builtins.foldl' (x: y: x + y) 0 (map (game:
    if (builtins.foldl' (x: y: x && y) true game.gameSet)
    then game.gameID
    else 0)
  processSets);
  sumSquareGameSets = builtins.foldl' (x: y: x + y) 0 (map (set: (builtins.foldl' (x: y: x * y) 1) set) minCubeSet);
in {
  taskA = lib.debug.traceVal sumGameIDs;
  taskB = lib.debug.traceVal sumSquareGameSets;
}

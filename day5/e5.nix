let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  rows = getRows rawdata;
  numberOfLines = builtins.length rows;

  seedList = map (elem: lib.toInt (builtins.head elem)) (builtins.filter (x: builtins.isList x) (builtins.split "([0-9]+)" (lib.lists.last (builtins.split ":" (builtins.elemAt rows 0)))));

  parseMapping = input:
    map (line: {
      destRangeStart = builtins.elemAt line 0;
      sourceRangeStart = builtins.elemAt line 1;
      rangeLength = builtins.elemAt line 2;
    })
    input;

  getMapData = mapType: rec {
    firstLine = lib.lists.findFirstIndex (x: x == "${mapType} map:") null rows;
    countLines = lib.lists.findFirstIndex (x: x == "") null (lib.lists.sublist firstLine numberOfLines rows) - 1;
    mappingInput = map (line: map (elem: lib.toInt (builtins.head elem)) (builtins.filter (x: builtins.isList x) (builtins.split "([0-9]+)" line))) (lib.lists.sublist (firstLine + 1) countLines rows);
    mappingData = parseMapping mappingInput;
  };

  mapList = [
    "seed-to-soil"
    "soil-to-fertilizer"
    "fertilizer-to-water"
    "water-to-light"
    "light-to-temperature"
    "temperature-to-humidity"
    "humidity-to-location"
  ];

  mapData = type: rec {
    mapType = type;
    mappings = (getMapData mapType).mappingData;
  };

  lookupMapping = source: mappingData: rec {
    search = builtins.filter (x: builtins.isInt x) (map (d:
      if source >= d.sourceRangeStart && source <= d.sourceRangeStart + d.rangeLength - 1
      then d.destRangeStart + source - d.sourceRangeStart
      else null)
    mappingData);
    result =
      if builtins.length search == 0
      then source
      else builtins.head search;
  };

  maps = map (m: mapData m) mapList;

  getCoordinate = seed: mapsInput: (lib.lists.foldl (input: map: (lookupMapping input map.mappings).result) seed mapsInput);

  closestCoordinate = seeds:
    lib.lists.foldl (a: b:
      if a == 0
      then b
      else lib.trivial.min a b)
    0 (map (s: getCoordinate s maps) seeds);
in {
  taskA = lib.debug.traceVal (closestCoordinate seedList);
}

let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./exampleA.txt;

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  rows = getRows rawdata;
  numberOfLines = builtins.length rows;

  seedList = map (elem: lib.toInt (builtins.head elem)) (builtins.filter (x: builtins.isList x) (builtins.split "([0-9]+)" (lib.lists.last (builtins.split ":" (builtins.elemAt rows 0)))));

  seedRanges = builtins.sort (a: b: a.sourceRangeStart < b.sourceRangeStart) (map (elem: {
    sourceRangeStart = lib.toInt (builtins.head (builtins.split " " (builtins.head elem)));
    rangeLength = lib.toInt (lib.lists.last (builtins.split " " (builtins.head elem)));
    shift = 0;
  }) (builtins.filter (x: builtins.isList x) (builtins.split "([0-9]+ [0-9]+)" (lib.lists.last (builtins.split ":" (builtins.elemAt rows 0))))));

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

  soilData = intersectRanges seedRanges (builtins.elemAt orderedMapList 0);
  fertData = intersectRanges soilData (builtins.elemAt orderedMapList 1);
  waterData = intersectRanges fertData (builtins.elemAt orderedMapList 2);
  lightData = intersectRanges waterData (builtins.elemAt orderedMapList 3);
  tempData = intersectRanges lightData (builtins.elemAt orderedMapList 4);

  genIntervals = ir: tr:
    if tr.sourceRangeStart <= ir.sourceRangeStart && tr.sourceRangeStart + tr.rangeLength - 1 > ir.sourceRangeStart
    then
      if tr.sourceRangeStart + tr.rangeLength - 1 >= ir.sourceRangeStart + ir.rangeLength - 1 # starts before and ends after
      then [
        {
          sourceRangeStart = ir.sourceRangeStart;
          rangeLength = ir.rangeLength;
          shift = ir.shift + tr.destRangeStart - tr.sourceRangeStart;
        }
      ]
      else [
        # starts before and ends before
        {
          sourceRangeStart = ir.sourceRangeStart;
          rangeLength = tr.rangeLength - (ir.sourceRangeStart - tr.sourceRangeStart);
          shift = ir.shift + tr.destRangeStart - tr.sourceRangeStart;
        }
        (
          if ir.shift != 0
          then rec {
            sourceRangeStart = tr.sourceRangeStart + tr.rangeLength;
            rangeLength = ir.rangeLength - (sourceRangeStart - ir.sourceRangeStart);
            shift = ir.shift;
          }
          else null
        )
      ]
    else if tr.sourceRangeStart > ir.sourceRangeStart && tr.sourceRangeStart + tr.rangeLength - 1 < ir.sourceRangeStart + ir.rangeLength - 1 #starts after and ends before
    then [
      (
        if ir.shift != 0
        then {
          sourceRangeStart = ir.sourceRangeStart;
          rangeLength = tr.sourceRangeStart - ir.sourceRangeStart;
          shift = ir.shift;
        }
        else null
      )
      {
        sourceRangeStart = tr.sourceRangeStart;
        rangeLength = tr.rangeLength;
        shift = ir.shift + tr.destRangeStart - tr.sourceRangeStart;
      }
      (
        if ir.shift != 0
        then rec {
          sourceRangeStart = tr.sourceRangeStart + tr.rangeLength;
          rangeLength = ir.sourceRangeStart + ir.rangeLength - sourceRangeStart;
          shift = ir.shift;
        }
        else null
      )
    ]
    else if tr.sourceRangeStart > ir.sourceRangeStart && tr.sourceRangeStart < ir.sourceRangeStart + ir.rangeLength - 1 #starts after and ends after
    then [
      (
        if ir.shift != 0
        then {
          sourceRangeStart = ir.sourceRangeStart;
          rangeLength = tr.sourceRangeStart - ir.sourceRangeStart;
          shift = ir.shift;
        }
        else null
      )
      {
        sourceRangeStart = tr.sourceRangeStart;
        rangeLength = ir.sourceRangeStart + ir.rangeLength - tr.sourceRangeStart;
        shift = ir.shift + tr.destRangeStart - tr.sourceRangeStart;
      }
    ]
    else [];

  intersectRanges = inputRanges: targetRanges:
    lib.lists.foldl (l: m:
      l
      ++ (
        if builtins.length m == 1
        then m
        else lib.lists.sublist 1 (builtins.length m) m
      )) []
    (map (
        ir:
          [ir]
          ++ (lib.lists.foldl (a: b: a ++ b) [] (map (tr: builtins.filter (x: !builtins.isNull x) (genIntervals ir tr)) targetRanges))
      )
      inputRanges);

  orderedMapList = map (m: builtins.sort (a: b: a.sourceRangeStart < b.sourceRangeStart) m.mappings) maps;

  consolidateMappings = lib.lists.foldl (s: t: intersectRanges s t) seedRanges orderedMapList;

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
  # taskA = lib.debug.traceVal (closestCoordinate seedList);
  taskB = lib.debug.traceValSeqN 4 tempData;

  # taskC = lib.debug.traceValSeqN 4 consolidateMappings;
  # taskD = lib.debug.traceValSeqN 4 (intersectRanges [
  #     {
  #       rangeLength = 13;
  #       shift = 0;
  #       sourceRangeStart = 55;
  #     }
  #     {
  #       rangeLength = 40;
  #       shift = 0;
  #       sourceRangeStart = 79;
  #     }
  #   ]
  #   soilData);
}
# reverseLookupMapping = source: mappingData: rec {
#   search = builtins.filter (x: builtins.isInt x) (map (d:
#     if source >= d.destRangeStart && source <= d.destRangeStart + d.rangeLength - 1
#     then d.destRangeStart + source - d.sourceRangeStart
#     else null)
#   mappingData);
#   result =
#     if builtins.length search == 0
#     then source
#     else builtins.head search;
# };
# seedExists = seed:
#   lib.lists.findFirst (x: x) false (map (sr:
#     if seed >= sr.seedStart && seed <= sr.seedStart + sr.rangeLength - 1
#     then true
#     else false)
#   seedRanges);
# revMaps = map (m: mapData m) (lib.lists.reverseList mapList);


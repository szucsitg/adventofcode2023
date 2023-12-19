{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-math.url = "github:xddxdd/nix-math";
  };

  outputs = inputs: let
    math = inputs.nix-math.lib.math;
    lib = inputs.nixpkgs.lib;

    rawdata = builtins.readFile ./input.txt;

    getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

    getElemements = n: map (x: lib.strings.toInt x) (builtins.filter (x: builtins.isString x && builtins.stringLength x > 0) (builtins.split "[ ]+" (lib.lists.last (builtins.split ":" (builtins.elemAt (getRows rawdata) n)))));
    timeList = getElemements 0;
    distanceList = getElemements 1;
    inputData = map (x: {
      time = builtins.elemAt timeList x;
      distance = builtins.elemAt distanceList x;
    }) (lib.lists.range 0 (builtins.length timeList - 1));

    concatPaddedText = n: lib.strings.toInt (lib.lists.foldl (a: b: a + b) "" (builtins.filter (x: builtins.isString x && builtins.stringLength x > 0) (builtins.split "[ ]+" (lib.lists.last (builtins.split ":" (builtins.elemAt (getRows rawdata) n))))));
    paddedTime = concatPaddedText 0;
    paddedDistance = concatPaddedText 1;

    getDistance = accTime: totalTime: accTime * (totalTime - accTime);
    iterateScenarios = totalTime: distance:
      lib.lists.foldl (a: b: a + b) 0 (map (accTime:
        if distance < getDistance accTime totalTime
        then 1
        else 0) (lib.lists.range 0 totalTime));
    b1 = totalTime: distance: builtins.floor ((totalTime + math.sqrt ((math.pow totalTime 2) - 4 * distance)) / 2);
    b2 = totalTime: distance: builtins.ceil ((totalTime - math.sqrt ((math.pow totalTime 2) - 4 * distance)) / 2);

    marginOfError = lib.lists.foldl (a: b: a * (iterateScenarios b.time b.distance)) 1 inputData;
  in {
    taskA = marginOfError;
    taskB = b1 paddedTime paddedDistance - b2 paddedTime paddedDistance + 1;
  };
}

let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  strToNum = s:
    builtins.replaceStrings [
      "one"
      "two"
      "three"
      "four"
      "five"
      "six"
      "seven"
      "eight"
      "nine"
    ] [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ] s;
  getList = r: builtins.filter builtins.isString (builtins.split "\n" r);

  findMatch = s:
    map (x: builtins.head x)
    (builtins.filter builtins.isList (builtins.split "([0-9])" s));
  calibrationValue = s:
    lib.toInt (builtins.head (findMatch s) + lib.lists.last (findMatch s));
  sumAll = l: builtins.foldl' (x: y: x + y) 0 (map (x: calibrationValue x) l);
in {
  taskA = lib.debug.traceVal (sumAll (getList rawdata));
  taskB = lib.debug.traceVal (sumAll (getList (strToNum rawdata)));
}

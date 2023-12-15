let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  matrixSize = builtins.stringLength (builtins.head (builtins.split "\n" rawdata));

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  input = getRows rawdata;

  splitPartsInput = map (row:
    map (elem:
      if builtins.isList elem
      then builtins.head elem
      else elem) (builtins.split "([0-9]+|[^.0-9]+)" row))
  input;

  parsePartsInput = lib.lists.foldl (a: b:
    a
    ++ lib.lists.foldl (c: d:
      c
      ++ (
        if d.isNumber || d.isSymbol
        then [d]
        else []
      )) []
    b) [] (map (rowNo:
    lib.lists.foldl (a: b:
      a
      ++ [
        {
          value = b;
          length = builtins.stringLength b;
          isNumber = !builtins.isNull (builtins.match "([0-9]+)" b);
          isSymbol = !builtins.isNull (builtins.match "([^.0-9]+)" b);
          rowIndex = rowNo;
          rowPosition =
            if builtins.length a == 0
            then 0
            else (lib.lists.last a).rowPosition + (lib.lists.last a).length;
        }
      ]) [] (builtins.elemAt splitPartsInput rowNo)) (lib.lists.range 0 (matrixSize - 1)));

  symbolList = builtins.filter (x: x.isSymbol) parsePartsInput;
  partsList = builtins.filter (x: x.isNumber) parsePartsInput;

  adjacentSymbol = partData:
    !builtins.isNull
    (lib.lists.findFirst (symbol:
        if
          (symbol.rowIndex >= partData.rowIndex - 1 && symbol.rowIndex <= partData.rowIndex + 1)
          && (
            symbol.rowPosition >= partData.rowPosition - 1 && symbol.rowPosition <= partData.rowPosition + partData.length
          )
        then true
        else false)
      null
      symbolList);

  findPartNumbers =
    lib.lists.foldl (a: b:
      a
      + (
        if (adjacentSymbol b)
        then lib.toInt b.value
        else 0
      ))
    0
    partsList;
in {
  taskA = lib.debug.traceValSeqN 4 findPartNumbers;
}

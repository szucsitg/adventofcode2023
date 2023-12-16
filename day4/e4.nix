let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  cardData = map (row: {
    cardID = getCardID row;
    winningNumbers = lib.lists.sublist 0 10 (getNumbers row);
    cardNumbers = lib.lists.sublist 10 35 (getNumbers row);
  }) (getRows rawdata);

  getCardID = row: lib.toInt (lib.lists.last (builtins.split " " (builtins.head (builtins.split ":" row))));
  getNumbers = row:
    builtins.filter (x: !builtins.isNull x)
    (map (elem:
      if builtins.isList elem
      then builtins.head elem
      else null) (builtins.split "([0-9]+)" (lib.lists.last (builtins.split ":" row))));

  calculatePoints = x:
    if x > 1
    then lib.lists.foldl (a: b: a * 2) 1 (lib.lists.range 0 (x - 2))
    else x;
  sumPoints = lib.lists.foldl (a: b: a + b) 0 (map (c: calculatePoints (builtins.length (builtins.filter (x: x) (map (n: builtins.elem n c.cardNumbers) c.winningNumbers)))) cardData);
in {
  taskA = lib.debug.traceVal sumPoints;
}

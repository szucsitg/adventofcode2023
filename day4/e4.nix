let
  lib = import <nixpkgs/lib>;

  rawdata = builtins.readFile ./input.txt;

  getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

  cardData = map (row: rec {
    cardID = getCardID row;
    winningNumbers = lib.lists.sublist 0 10 (getNumbers row);
    cardNumbers = lib.lists.sublist 10 25 (getNumbers row);
    countWins = builtins.length (builtins.filter (x: x) (map (n: builtins.elem n cardNumbers) winningNumbers));
    cardCount = 1;
  }) (getRows rawdata);
  noOfCards = builtins.length cardData;

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
  sumPoints = lib.lists.foldl (a: b: a + b) 0 (map (c: calculatePoints (c.countWins)) cardData);

  copyScratchcards = lib.lists.foldl (cd: iter:
    map (
      c:
        if
          c.cardID
          <= ((builtins.elemAt cd iter).countWins + (builtins.elemAt cd iter).cardID)
          && c.cardID > (builtins.elemAt cd iter).cardID
        then
          c
          // {
            cardCount = c.cardCount + (builtins.elemAt cd iter).cardCount;
          }
        else c
    )
    cd)
  cardData (lib.lists.range 0 (noOfCards - 1));

  countScratchcards = lib.lists.foldl (a: b: a + b.cardCount) 0 copyScratchcards;
in {
  taskA = lib.debug.traceVal sumPoints;
  taskB = lib.debug.traceVal countScratchcards;
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-math.url = "github:xddxdd/nix-math";
  };

  outputs = inputs: let
    math = inputs.nix-math.lib.math;
    lib = inputs.nixpkgs.lib;

    rawdata = builtins.readFile ./input.txt;

    cardValues = {
      A = 14;
      K = 13;
      Q = 12;
      J = 11;
      T = 10;
    };
    jokerValues = {
      A = 14;
      K = 13;
      Q = 12;
      J = 1;
      T = 10;
    };
    letterCards = builtins.attrNames cardValues;
    jokerCards = builtins.attrNames jokerValues;

    getCardValue = c:
      if builtins.any (x: x == "${c}") letterCards
      then cardValues.${c}
      else lib.strings.toInt c;
    getJokerCardValue = c:
      if builtins.any (x: x == "${c}") jokerCards
      then jokerValues.${c}
      else lib.strings.toInt c;
    getRows = r: builtins.filter builtins.isString (builtins.split "\n" r);

    getValue = attrset: builtins.head (lib.attrsets.attrValues attrset);
    getCard = attrset: builtins.head (builtins.attrNames attrset);

    countCards = hand:
      builtins.sort (
        a: b:
          getValue a
          > getValue b
          || (
            getValue a
            == getValue b
            && getCardValue (getCard a) > getCardValue (getCard b)
          )
      ) (map (c: {${c} = lib.lists.count (hc: hc == c) hand;}) (lib.lists.unique hand));

    countJoker = cc:
      lib.lists.foldl (s: c:
        if getCard c == "J"
        then getValue c
        else s)
      0
      cc;
    filterJoker = cc:
      lib.lists.foldl (
        h: c:
          if getCard c == "J"
          then h
          else
            h
            ++ [c]
      ) []
      cc;
    applyJoker = cc:
      if (countJoker cc) > 0
      then let
        fh = filterJoker cc;
        first = builtins.elemAt fh 0;
        card = getCard first;
        onlyJoker =
          if builtins.length fh == 0
          then true
          else false;
      in
        if onlyJoker
        then cc
        else [{${card} = first.${card} + countJoker cc;}] ++ (lib.lists.sublist 1 3 fh)
      else cc;

    getType = cc: let
      counts = map (c: getValue c) cc;
    in (
      if counts == [5] # five of a kind
      then 7
      else if counts == [4 1] # four of a kind
      then 6
      else if counts == [3 2] # full house
      then 5
      else if counts == [3 1 1] # three of a kind
      then 4
      else if counts == [2 2 1] # two pair
      then 3
      else if counts == [2 1 1 1] # one pair
      then 2
      else 1
    );

    getHand = row: builtins.head (builtins.split " " row);
    getBid = row: lib.strings.toInt (lib.lists.last (builtins.split " " row));
    parseHand = hand:
      map (
        card: let
          rawCard = builtins.head card;
        in
          rawCard
      ) (builtins.filter (x: builtins.isList x) (builtins.split "(.)" hand));

    allHands = map (row: let
      hand = getHand row;
    in rec {
      parsedHand = parseHand hand;
      bid = getBid row;
      countedCards = countCards parsedHand;
      jokerCards = applyJoker countedCards;
      type = getType countedCards;
      jokerType = getType jokerCards;
    }) (getRows rawdata);

    strongerHand = a: b:
      lib.lists.foldl (i: s:
        if getCardValue (builtins.elemAt a s) != getCardValue (builtins.elemAt b s) && builtins.isNull i
        then
          if getCardValue (builtins.elemAt a s) > getCardValue (builtins.elemAt b s)
          then true
          else false
        else if builtins.isNull i
        then null
        else i)
      null (lib.lists.range 0 4);

    strongerJokerHand = a: b:
      lib.lists.foldl (i: s:
        if getJokerCardValue (builtins.elemAt a s) != getJokerCardValue (builtins.elemAt b s) && builtins.isNull i
        then
          if getJokerCardValue (builtins.elemAt a s) > getJokerCardValue (builtins.elemAt b s)
          then true
          else false
        else if builtins.isNull i
        then null
        else i)
      null (lib.lists.range 0 4);

    rankHands = builtins.sort (a: b: a.type < b.type || (a.type == b.type && !strongerHand a.parsedHand b.parsedHand)) allHands;

    rankJokerHands = builtins.sort (a: b: a.jokerType < b.jokerType || (a.jokerType == b.jokerType && !strongerJokerHand a.parsedHand b.parsedHand)) allHands;

    totalWinnings = lib.lists.foldl (a: b: a + (builtins.elemAt rankHands (b - 1)).bid * b) 0 (lib.lists.range 1 (builtins.length rankHands));

    totalJokerWinnings = lib.lists.foldl (a: b: a + (builtins.elemAt rankJokerHands (b - 1)).bid * b) 0 (lib.lists.range 1 (builtins.length rankJokerHands));
  in {
    taskA = totalWinnings;
    taskB = totalJokerWinnings;
  };
}

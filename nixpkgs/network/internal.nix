{
  lib ? import ../.,
}:
let
  inherit (builtins)
    map
    match
    genList
    length
    concatMap
    head
    toString
    ;

  inherit (lib) lists strings trivial;

  inherit (lib.lists) last;

  ipv6Bits = 128;
  ipv6Pieces = 8; # 'x:x:x:x:x:x:x:x'
  ipv6PieceBits = 16; # One piece in range from 0 to 0xffff.
  ipv6PieceMaxValue = 65535; # 2^16 - 1
in
let

  expandIpv6 =
    addr:
    if match "^[0-9A-Fa-f:]+$" addr == null then
      throw "${addr} contains malformed characters for IPv6 address"
    else
      let
        pieces = strings.splitString ":" addr;
        piecesNoEmpty = lists.remove "" pieces;
        piecesNoEmptyLen = length piecesNoEmpty;
        zeros = genList (_: "0") (ipv6Pieces - piecesNoEmptyLen);
        hasPrefix = strings.hasPrefix "::" addr;
        hasSuffix = strings.hasSuffix "::" addr;
        hasInfix = strings.hasInfix "::" addr;
      in
      if addr == "::" then
        zeros
      else if
        let
          emptyCount = length pieces - piecesNoEmptyLen;
          emptyExpected =
            # splitString produces two empty pieces when "::" in the beginning
            # or in the end, and only one when in the middle of an address.
            if hasPrefix || hasSuffix then
              2
            else if hasInfix then
              1
            else
              0;
        in
        emptyCount != emptyExpected
        || (hasInfix && piecesNoEmptyLen >= ipv6Pieces) # "::" compresses at least one group of zeros.
        || (!hasInfix && piecesNoEmptyLen != ipv6Pieces)
      then
        throw "${addr} is not a valid IPv6 address"
      # Create a list of 8 elements, filling some of them with zeros depending
      # on where the "::" was found.
      else if hasPrefix then
        zeros ++ piecesNoEmpty
      else if hasSuffix then
        piecesNoEmpty ++ zeros
      else if hasInfix then
        concatMap (piece: if piece == "" then zeros else [ piece ]) pieces
      else
        pieces;

  parseExpandedIpv6 =
    addr:
    assert lib.assertMsg (
      length addr == ipv6Pieces
    ) "parseExpandedIpv6: expected list of integers with ${ipv6Pieces} elements";
    let
      u16FromHexStr =
        hex:
        let
          parsed = trivial.fromHexString hex;
        in
        if 0 <= parsed && parsed <= ipv6PieceMaxValue then
          parsed
        else
          throw "0x${hex} is not a valid u16 integer";
    in
    map (piece: u16FromHexStr piece) addr;
in
let

  parseIpv6FromString = addr: parseExpandedIpv6 (expandIpv6 addr);
in
{

  _ipv6 = {

    toStringFromExpandedIp =
      pieces: strings.concatMapStringsSep ":" (piece: strings.toLower (trivial.toHexString piece)) pieces;

    split =
      addr:
      let
        splitted = strings.splitString "/" addr;
        splittedLength = length splitted;
      in
      if splittedLength == 1 then # [ ip ]
        {
          address = parseIpv6FromString addr;
          prefixLength = ipv6Bits;
        }
      else if splittedLength == 2 then # [ ip subnet ]
        {
          address = parseIpv6FromString (head splitted);
          prefixLength =
            let
              n = strings.toInt (last splitted);
            in
            if 1 <= n && n <= ipv6Bits then
              n
            else
              throw "${addr} IPv6 subnet should be in range [1;${toString ipv6Bits}], got ${toString n}";
        }
      else
        throw "${addr} is not a valid IPv6 address in CIDR notation";
  };
}

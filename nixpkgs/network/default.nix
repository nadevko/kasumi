{ lib }:
let
  inherit (import ./internal.nix { inherit lib; }) _ipv6;
  inherit (lib.strings) match concatStringsSep toLower;
  inherit (lib.trivial)
    pipe
    bitXor
    fromHexString
    toHexString
    ;
  inherit (lib.lists) elemAt;
in
{
  ipv6 = {

    fromString =
      addr:
      let
        splittedAddr = _ipv6.split addr;

        addrInternal = splittedAddr.address;
        prefixLength = splittedAddr.prefixLength;

        address = _ipv6.toStringFromExpandedIp addrInternal;
      in
      {
        inherit address prefixLength;
      };

    mkEUI64Suffix =
      mac:
      pipe mac [
        # match mac address
        (match "^([0-9A-Fa-f]{2})[-:.]?([0-9A-Fa-f]{2})[-:.]?([0-9A-Fa-f]{2})[-:.]?([0-9A-Fa-f]{2})[-:.]?([0-9A-Fa-f]{2})[-:.]?([0-9A-Fa-f]{2})$")

        # check if there are matches
        (
          matches:
          if matches == null then
            throw ''"${mac}" is not a valid MAC address (expected 6 octets of hex digits)''
          else
            matches
        )

        # transform to result hextets
        (octets: [
          # combine 1st and 2nd octets into first hextet, flip U/L bit, 512 = 0x200
          (toHexString (bitXor 512 (fromHexString ((elemAt octets 0) + (elemAt octets 1)))))

          # combine 3rd and 4th octets, combine them, insert fffe pattern in between to get next two hextets
          "${elemAt octets 2}ff"
          "fe${elemAt octets 3}"

          # combine 5th and 6th octets into the last hextet
          ((elemAt octets 4) + (elemAt octets 5))
        ])

        # concat to result suffix
        (concatStringsSep ":")

        toLower
      ];
  };
}

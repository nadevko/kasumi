# snippets that can be shared by multiple fetchers (pkgs/build-support)
{ lib }:
let
  commonH = hashTypes: rec {
    hashNames = [ "hash" ] ++ hashTypes;
    hashSet = lib.genAttrs hashNames (lib.const { });
  };

  fakeH = {
    hash = lib.fakeHash;
    sha256 = lib.fakeSha256;
    sha512 = lib.fakeSha512;
  };
in
rec {

  proxyImpureEnvVars = [
    # We borrow these environment variables from the caller to allow
    # easy proxy configuration.  This is impure, but a fixed-output
    # derivation like fetchurl is allowed to do so since its result is
    # by definition pure.
    "http_proxy"
    "https_proxy"
    "ftp_proxy"
    "all_proxy"
    "no_proxy"
    "HTTP_PROXY"
    "HTTPS_PROXY"
    "FTP_PROXY"
    "ALL_PROXY"
    "NO_PROXY"

    # https proxies typically need to inject custom root CAs too
    "NIX_SSL_CERT_FILE"
  ];

  normalizeHash =
    {
      hashTypes ? [ "sha256" ],
      required ? true,
    }:
    let
      inherit (lib)
        concatMapStringsSep
        head
        tail
        throwIf
        ;
      inherit (lib.attrsets)
        attrsToList
        intersectAttrs
        removeAttrs
        optionalAttrs
        ;

      inherit (commonH hashTypes) hashNames hashSet;
    in
    args:
    if args ? "outputHash" then
      args
    else
      let
        # The argument hash, as a {name, value} pair
        h =
          # All hashes passed in arguments (possibly 0 or >1) as a list of {name, value} pairs
          let
            hashesAsNVPairs = attrsToList (intersectAttrs hashSet args);
          in
          if hashesAsNVPairs == [ ] then
            throwIf required "fetcher called without `hash`" null
          else if tail hashesAsNVPairs != [ ] then
            throw "fetcher called with mutually-incompatible arguments: ${
              concatMapStringsSep ", " (a: a.name) hashesAsNVPairs
            }"
          else
            head hashesAsNVPairs;
      in
      removeAttrs args hashNames
      // (optionalAttrs (h != null) {
        outputHashAlgo = if h.name == "hash" then null else h.name;
        outputHash =
          if h.value == "" then
            fakeH.${h.name} or (throw "no “fake hash” defined for ${h.name}")
          else
            h.value;
      });

  withNormalizedHash =
    {
      hashTypes ? [ "sha256" ],
    }:
    fetcher:
    let
      inherit (lib.attrsets) intersectAttrs removeAttrs;
      inherit (lib.trivial) functionArgs setFunctionArgs;

      inherit (commonH hashTypes) hashSet;
      fArgs = functionArgs fetcher;

      normalize = normalizeHash {
        inherit hashTypes;
        required = !fArgs.outputHash;
      };
    in
    # The o.g. fetcher must *only* accept outputHash and outputHashAlgo
    assert fArgs ? outputHash && fArgs ? outputHashAlgo;
    assert intersectAttrs fArgs hashSet == { };

    setFunctionArgs (args: fetcher (normalize args)) (
      removeAttrs fArgs [
        "outputHash"
        "outputHashAlgo"
      ]
      // {
        hash = fArgs.outputHash;
      }
    );
}

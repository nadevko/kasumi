# like in nix (Nix) 2.31.3
# - [builtins.parseFlakeRef](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flake-primops.cc#L59-L98)
# - [flakeref.cc](https://github.com/NixOS/nix/blob/2.31.3/src/libflake/flakeref.cc)
[
  {
    args = [ "/tmp///kasumi" ];
    expected = {
      path = "/tmp///kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "/tmp/kasumi" ];
    expected = {
      path = "/tmp/kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "0kasumi" ];
    success = false;
    error = "flake reference '[1;35m0kasumi[0m' is not an absolute path";
  }
  {
    args = [ "flake:kasumi" ];
    expected = {
      id = "kasumi";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "flake:kasumi/" ];
    expected = {
      id = "kasumi";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "git@nadevko.cc:nadevko/kasumi.git" ];
    error = "flake reference '[1;35mgit@nadevko.cc:nadevko/kasumi.git[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "git+https://github.com/nadevko/kasumi.git" ];
    expected = {
      type = "git";
      url = "https://github.com/nadevko/kasumi.git";
    };
    success = true;
  }
  {
    args = [ "git+https://nadevko.cc/kasumi.git#master" ];
    error = "unexpected fragment '[1;35mmaster[0m' in flake reference '[1;35m[1;35mgit+https://nadevko.cc/kasumi.git#master[0m'";
    success = false;
  }
  {
    args = [ "git+mailto:nadevko@nadevko.cc" ];
    error = "input '[1;35mgit+mailto:nadevko@nadevko.cc[0m' is unsupported";
    success = false;
  }
  {
    args = [ "github:" ];
    success = false;
    error = "flake reference '[1;35mgithub:[0m' is not an absolute path";
  }
  {
    args = [ "github:/kas?mi" ];
    warns = [
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
    ];
    error = "flake reference '[1;35mgithub:/kas?mi[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "github:/kas?mi&&" ];
    warns = [
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
    ];
    error = "flake reference '[1;35mgithub:/kas?mi&&[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "github:/kas?mi&&c" ];
    warns = [
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
    ];
    error = "flake reference '[1;35mgithub:/kas?mi&&c[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "github:/kas?mi&&c=" ];
    warns = [
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
    ];
    error = "flake reference '[1;35mgithub:/kas?mi&&c=[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "github:/kas?mi&&c=&&" ];
    warns = [
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
      "[1;35mwarning:[0m dubious URI query '' is missing equal sign '=', ignoring"
    ];
    error = "flake reference '[1;35mgithub:/kas?mi&&c=[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "github:/kasumi" ];
    success = false;
    error = "flake reference '[1;35mgithub:/kasumi[0m' is not an absolute path";
  }
  {
    args = [ "github:nadevko/" ];
    success = false;
    error = "flake reference '[1;35mgithub:nadevko/[0m' is not an absolute path";
  }
  {
    args = [ "github:nadevko/kas?mi" ];
    expected = {
      owner = "nadevko";
      repo = "kas";
      type = "github";
    };
    warns = [ "[1;35mwarning:[0m dubious URI query 'mi' is missing equal sign '=', ignoring" ];
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi?" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi?dir=" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi?dir=foo/bar/baz" ];
    expected = {
      dir = "foo/bar/baz";
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi?dir=foo/bar/baz&foo=bar" ];
    expected = {
      dir = "foo/bar/baz";
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi?dir=lib#attr" ];
    error = "unexpected fragment '[1;35mattr[0m' in flake reference '[1;35m[1;35mgithub:nadevko/kasumi?dir=lib#attr[0m'";
    success = false;
  }
  {
    args = [ "github:nadevko/kasumi?foo=bar" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi%2Alib" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi*lib";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "github:nadevko/kasumi%2Flib" ];
    expected = {
      owner = "nadevko";
      ref = "lib";
      repo = "kasumi";
      type = "github";
    };
    success = true;
  }
  {
    args = [ "githuh:nadevko/kasumi" ];
    error = "input '[1;35mgithuh:nadevko/kasumi[0m' is unsupported";
    success = false;
  }
  {
    args = [ "gitlab:nadevko//kasumi" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "gitlab";
    };
    success = true;
  }
  {
    args = [ "gitlab:nadevko/kasumi" ];
    expected = {
      owner = "nadevko";
      repo = "kasumi";
      type = "gitlab";
    };
    success = true;
  }
  {
    args = [ "https://nadevko.cc//" ];
    expected = {
      type = "tarball";
      url = "https://nadevko.cc//";
    };
    success = true;
  }
  {
    args = [ "https://nadevko.cc/kasumi.tar.gz" ];
    expected = {
      type = "tarball";
      url = "https://nadevko.cc/kasumi.tar.gz";
    };
    success = true;
  }
  {
    args = [ "kasumi?&&&" ];
    error = "flake reference '[1;35mkasumi?&&&[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "kasumi?a=b=c" ];
    error = "flake reference '[1;35mkasumi?a=b=c[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "kasumi?dir=foo&dir=bar" ];
    error = "flake reference '[1;35mkasumi?dir=foo&dir=bar[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "kasumi" ];
    expected = {
      id = "kasumi";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "kasumi//master" ];
    error = "flake reference '[1;35mkasumi//master[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "kasumi/0123456789abcdef0123456789abcdef01234567" ];
    expected = {
      id = "kasumi";
      rev = "0123456789abcdef0123456789abcdef01234567";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "kasumi/0123456789abcdef0123456789abcdef01234567/master" ];
    error = "in flake URL '[1;35mflake://kasumi/0123456789abcdef0123456789abcdef01234567/master[0m', '[1;31mmaster[0m' is not a commit hash";
    success = false;
  }
  {
    args = [ "kasumi/a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b" ];
    expected = {
      id = "kasumi";
      ref = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "kasumi/master?ref=dev" ];
    error = "flake reference '[1;35mkasumi/master?ref=dev[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "kasumi/master" ];
    expected = {
      id = "kasumi";
      ref = "master";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "kasumi/master/0123456789abcdef0123456789abcdef01234567" ];
    expected = {
      id = "kasumi";
      ref = "master";
      rev = "0123456789abcdef0123456789abcdef01234567";
      type = "indirect";
    };
    success = true;
  }
  {
    args = [ "kasumi#pkg" ];
    error = "unexpected fragment '[1;35mpkg[0m' in flake reference '[1;35m[1;35mkasumi#pkg[0m'";
    success = false;
  }
  {
    args = [ "path:./" ];
    expected = {
      path = "./";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:./kasumi" ];
    expected = {
      path = "./kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:/home/nadevko///kasumi" ];
    expected = {
      path = "/home/nadevko///kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:/home/nadevko/kasumi" ];
    expected = {
      path = "/home/nadevko/kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:/kas\\umi" ];
    error = "flake reference '[1;35mpath:/kas\\umi[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "path:/tmp/kasumi" ];
    expected = {
      path = "/tmp/kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:/tmp/kasumi#" ];
    expected = {
      path = "/tmp/kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:/tmp/kasumi##" ];
    error = "unexpected fragment '[1;35m#[0m' in flake reference '[1;35m[1;35mpath:/tmp/kasumi##[0m'";
    success = false;
  }
  {
    args = [ "path:\/" ];
    expected = {
      path = "/";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:\/kas\umi" ];
    expected = {
      path = "/kasumi";
      type = "path";
    };
    success = true;
  }
  {
    args = [ "path:\/kas\umi\n" ];
    error = "flake reference '[1;35mpath:/kasumi\n[0m' is not an absolute path";
    success = false;
  }
  {
    args = [ "sourcehut:~nadevko/kasumi" ];
    expected = {
      owner = "~nadevko";
      repo = "kasumi";
      type = "sourcehut";
    };
    success = true;
  }
  {
    args = [ (x: x) ];
    error = "expected a string but found [1;35ma function[0m: [1;36m«lambda @ «string»:1:4»[0m";
    success = false;
  }
  {
    args = [ [ "kasumi" ] ];
    error = "expected a string but found [1;35ma list[0m: [ [1;35m\"kasumi\"[0m ]";
    success = false;
  }
  {
    args = [ { } ];
    error = "expected a string but found [1;35ma set[0m: { }";
    success = false;
  }
  {
    args = [
      {
        type = "github";
        owner = "nadevko";
        repo = "kasumi";
      }
    ];
    error = "expected a string but found [1;35ma set[0m: { type = [1;35m\"github\"[0m; owner = [1;35m\"nadevko\"[0m; repo = [1;35m\"kasumi\"[0m; }";
    success = false;
  }
  {
    args = [ /tmp/kasumi ];
    error = "expected a string but found [1;35ma path[0m: [1;32m/tmp/kasumi[0m";
    success = false;
  }
  {
    args = [ 42 ];
    error = "expected a string but found [1;35man integer[0m: [1;36m42[0m";
    success = false;
  }
  {
    args = [ 42.0 ];
    error = "expected a string but found [1;35ma float[0m: [1;36m42[0m";
    success = false;
  }
  {
    args = [ 42.2 ];
    error = "expected a string but found [1;35ma float[0m: 4[1;36m2.2[0m";
    success = false;
  }
  {
    args = [ null ];
    error = "expected a string but found [1;35mnull[0m: [1;36mnull[0m";
    success = false;
  }
  {
    args = [ true ];
    error = "expected a string but found [1;35ma Boolean[0m: [1;36mtrue[0m";
    success = false;
  }
]

(import
  (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      src = lock.nodes.nixpkgs.locked;
    in
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${src.rev}.tar.gz";
      sha256 = src.narHash;
    }
  )
  {
    config.permittedInsecurePackages = [
      "python-2.7.18.8"
      "qtwebkit-5.212.0-alpha4"
    ];
  }
).callPackage
  ./openmodelica.nix
  {
    openmodelica-core =
      (import <nixpkgs> {
        config.permittedInsecurePackages = [
          "python-2.7.18.8"
          "qtwebkit-5.212.0-alpha4"
        ];
      }).callPackage
        ./openmodelica-core.nix
        { };
  }

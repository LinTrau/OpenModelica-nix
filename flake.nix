{
  description = "OpenModelica 1.25.0 — built from source for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            "python-2.7.18.8"
            "qtwebkit-5.212.0-alpha4"
            "qtwebengine-5.15.19"
            "python-2.7.18.12"
          ];
        };

        openmodelica-core = pkgs.callPackage ./openmodelica-core.nix { };
        openmodelica = pkgs.callPackage ./openmodelica.nix {
          inherit openmodelica-core;
        };
      in
      {
        # ── Packages ──────────────────────────────────────────────────────────
        packages = {
          inherit openmodelica-core openmodelica;
          default = openmodelica;
        };

        # ── Dev shell (兼容原来的 nix-shell 用法) ─────────────────────────────
        devShells.default = pkgs.mkShell {
          packages = [ openmodelica ];
        };
      }
    )
    // {
      # ── Overlay（可在其他 flake 中使用） ──────────────────────────────────
      overlays.default = final: prev: {
        openmodelica-core = final.callPackage ./openmodelica-core.nix { };
        openmodelica = final.callPackage ./openmodelica.nix {
          openmodelica-core = final.openmodelica-core;
        };
        qt5 = prev.qt5.overrideScope (
          finalQt: prevQt: {
            qtwebkit = prevQt.qtwebkit.overrideAttrs (oldAttrs: {
              cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
                "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
                "-DCMAKE_CXX_STANDARD=14"
              ];
              env = (oldAttrs.env or { }) // {
                NIX_CFLAGS_COMPILE = (oldAttrs.NIX_CFLAGS_COMPILE or "") + " -std=c++14 -fpermissive";
              };
            });
          }
        );
      };

      # ── NixOS module（可直接加入 configuration.nix） ──────────────────────
      nixosModules.default =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          cfg = config.programs.openmodelica;
          omPkgs = import nixpkgs {
            inherit (pkgs.stdenv.hostPlatform) system;
            overlays = [ self.overlays.default ];
            config.permittedInsecurePackages = [
              "python-2.7.18.8"
              "qtwebkit-5.212.0-alpha4"
              "qtwebengine-5.15.19"
              "python-2.7.18.12"
            ];
          };
          openmodelica-core = omPkgs.callPackage ./openmodelica-core.nix { };
          openmodelica = omPkgs.callPackage ./openmodelica.nix {
            inherit openmodelica-core;
          };
        in
        {
          options.programs.openmodelica = {
            enable = lib.mkEnableOption "OpenModelica modeling and simulation environment";
          };

          config = lib.mkIf cfg.enable {
            nixpkgs.config.permittedInsecurePackages = [
              "python-2.7.18.8"
              "qtwebkit-5.212.0-alpha4"
              "qtwebengine-5.15.19"
              "python-2.7.18.12"
            ];

            environment.systemPackages = [ openmodelica ];
          };
        };
    };
}

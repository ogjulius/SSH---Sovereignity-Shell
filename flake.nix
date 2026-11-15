{
  description = "SSH — Sovereignity Shell: a spatial Quickshell desktop shell for Hyprland and Niri";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAll (pkgs: rec {
        ssh-shell = pkgs.callPackage ./packaging/nixos/package.nix { };
        default = ssh-shell;
      });

      nixosModules.default = import ./packaging/nixos/module.nix self;

      devShells = forAll (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.quickshell pkgs.qt6.qtdeclarative ]; };
      });
    };
}

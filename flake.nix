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

      # A minimal declarative example (also evaluated in CI).
      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.default
          ({ ... }: {
            programs.ssh-shell.enable = true;
            boot.loader.grub.enable = false;
            fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
            system.stateVersion = "25.05";
          })
        ];
      };

      checks = forAll (pkgs: {
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.quickshell pkgs.qt6.qtdeclarative ]; };
      });
    };
}

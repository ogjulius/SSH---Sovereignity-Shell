# NixOS module:  imports = [ ssh-shell.nixosModules.default ];
#                programs.ssh-shell.enable = true;
self: { config, lib, pkgs, ... }:
let cfg = config.programs.ssh-shell;
in {
  options.programs.ssh-shell = {
    enable = lib.mkEnableOption "SSH — Sovereignity Shell";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The SSH package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    fonts.packages = [ pkgs.inter pkgs.jetbrains-mono ];
    # Services SSH reads when present; enabling them is the user's choice.
    services.upower.enable = lib.mkDefault true;
  };
}

# NixOS module:  imports = [ ssh-shell.nixosModules.default ];
#                programs.ssh-shell = {
#                  enable = true;
#                  hyprland.enable = true;   # and/or
#                  niri.enable = true;
#                };
#
# Adds the "Sovereignity Shell (Hyprland)" / "(Niri)" login sessions to the
# display manager. The plain Hyprland/Niri sessions stay available.
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
    hyprland.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Hyprland (programs.hyprland) for the Sovereignity Shell (Hyprland) session.";
    };
    niri.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Niri (programs.niri) for the Sovereignity Shell (Niri) session.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    fonts.packages = [ pkgs.inter pkgs.jetbrains-mono ];
    # Registers ssh-hyprland.desktop and ssh-niri.desktop with the display
    # manager. A session whose compositor is missing is hidden (TryExec).
    services.displayManager.sessionPackages = [ cfg.package ];
    programs.hyprland.enable = lib.mkIf cfg.hyprland.enable (lib.mkDefault true);
    programs.niri.enable = lib.mkIf cfg.niri.enable (lib.mkDefault true);
    # Services SSH reads when present; enabling them is the user's choice.
    services.upower.enable = lib.mkDefault true;
  };
}

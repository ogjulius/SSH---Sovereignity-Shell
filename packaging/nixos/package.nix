# Nix package for SSH. The QML tree is installed into the store and the
# ssh-shell wrapper is pointed at it; no mutable paths are assumed.
{ lib, stdenvNoCC, makeWrapper, quickshell, brightnessctl }:

stdenvNoCC.mkDerivation {
  pname = "ssh-shell";
  version = "0.1.0-alpha";
  src = lib.cleanSource ../..;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    make install DESTDIR=$out PREFIX=
    # Run the wrapper against the store copy and make its runtime tools available.
    wrapProgram $out/bin/ssh-shell \
      --set SSH_SHELL_DIR $out/share/ssh-shell \
      --prefix PATH : ${lib.makeBinPath [ quickshell brightnessctl ]}
    runHook postInstall
  '';

  meta = {
    description = "Spatial Quickshell desktop shell for Hyprland and Niri";
    homepage = "https://github.com/ogjulius/SSH---Sovereignity-Shell";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ssh-shell";
  };
}

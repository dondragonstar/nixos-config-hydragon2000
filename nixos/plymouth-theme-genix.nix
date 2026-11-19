{ stdenvNoCC }:

# Plymouth theme for the Genix7000 spin.
#
# The generated genix.plymouth uses @SHARE@ as a placeholder for the theme
# directory. NixOS's plymouth module rewrites `/nix/store/.../share/plymouth/
# themes` prefixes inside the initrd with `sed`, so the paths here MUST be
# store paths -- never /usr/share (which does not exist in the initrd).
stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-genix";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plymouth/themes/genix
    cp -r ${./genix}/. $out/share/plymouth/themes/genix/
    substituteInPlace $out/share/plymouth/themes/genix/genix.plymouth \
      --replace-fail '@SHARE@' "$out/share/plymouth/themes"
    runHook postInstall
  '';

  meta = {
    description = "Genix7000 Nix logo spin, rendered with manim";
    platforms = [ "x86_64-linux" ];
  };
}

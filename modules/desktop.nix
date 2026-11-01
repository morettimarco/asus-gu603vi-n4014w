{ pkgs, ... }:

# WORKAROUND(powerdevil-dimdisplay-display-gap): see workarounds.json.
# Optional fix for a keyboard that stays dark after an idle suspend, even after
# you press a key (KDE bug 523402). Off by default until KDE fixes it upstream.
# To enable it, uncomment the let block here and the systemPackages line below,
# rebuild, and run `systemctl --user restart plasma-powerdevil`.
# Displays vanish briefly on resume, so DimDisplay counts as unsupported and is
# destroyed along with the keyboard brightness it saved. This keeps it alive
# when a keyboard backlight exists. hiPrio limits the rebuild to powerdevil; an
# overlay would also rebuild the Plasma packages that depend on it.
# let
#   powerdevilKeepDimDisplay = pkgs.kdePackages.powerdevil.overrideAttrs (old: {
#     postPatch = (old.postPatch or "") + ''
#       substituteInPlace daemon/actions/bundled/dimdisplay.cpp \
#         --replace-fail \
#           'return core()->screenBrightnessController()->isSupported();' \
#           'return core()->screenBrightnessController()->isSupported() || core()->keyboardBrightnessController()->isSupported();'
#     '';
#   });
# in
{
  # environment.systemPackages = [ (pkgs.lib.hiPrio powerdevilKeepDimDisplay) ];  # WORKAROUND(powerdevil-dimdisplay-display-gap)

  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE PIM (Akonadi + KMail/Kontact/Merkuro). Plasma enables it via
  # mkDefault, and since nixpkgs 2026-10 the app sub-options follow it, so a
  # flake update silently installs a full mail/calendar suite. Set to true if
  # you want it.
  programs.kde-pim.enable = false;
}

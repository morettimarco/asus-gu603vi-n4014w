{ pkgs, ... }:

{
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

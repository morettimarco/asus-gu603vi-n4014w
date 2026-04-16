{ pkgs, lib, inputs, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;
in
{
  # --- Niri compositor ---
  programs.niri.enable = true;

  qt.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    xwayland-satellite
    tokyonight-gtk-theme
    swayimg
    rose-pine-cursor
    papirus-icon-theme
    nemo
    fuzzel
    wl-clipboard
    libsForQt5.qt5ct
    mpvpaper
    brightnessctl
    pamixer
    grim
    slurp
    ghostty
    foot       # lightweight fallback terminal (no GPU accel needed)
  ] ++ lib.optionals isX86 [
    gpu-screen-recorder  # x86_64 only
  ];

  # --- Login: tuigreet → niri-session ---
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd niri-session";
        user = "greeter";
      };
      initial_session = {
        command = "niri-session";
        user = "marco";
      };
    };
  };

  # --- XDG portal for screen sharing, file dialogs, etc. ---
  xdg.portal.enable = true;

  # --- Fonts ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter
  ];
}

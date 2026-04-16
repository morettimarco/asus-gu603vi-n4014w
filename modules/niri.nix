{ pkgs, inputs, ... }:

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
    gpu-screen-recorder
    wl-clipboard
    libsForQt5.qt5ct
    mpvpaper
    brightnessctl
    pamixer
    grim
    slurp
    ghostty
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

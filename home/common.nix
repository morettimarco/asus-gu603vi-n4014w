{ pkgs, ... }:

{
  home = {
    username = "marco";
    homeDirectory = "/home/marco";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "Marco Moretti";
      user.email = "marco.moretti@gmail.com";
      core.editor = "vim";
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = true;
      truecolor = true;
    };
  };
}

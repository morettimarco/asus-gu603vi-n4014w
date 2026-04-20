{ pkgs, ... }:

{
  home = {
    username = "CHANGEME_USERNAME";
    homeDirectory = "/home/CHANGEME_USERNAME";
    stateVersion = "25.11";
    packages = with pkgs; [
      obsidian
    ];
  };

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "CHANGEME_FULL_NAME";
      user.email = "CHANGEME_EMAIL";
      core.editor = "vim";
      credential.helper = "!gh auth git-credential";
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

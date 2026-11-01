{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    claude-code

    # Diagnostics & monitoring
    pciutils          # lspci
    usbutils          # lsusb
    lm_sensors        # sensors (CPU/GPU temperatures)
    nvtopPackages.full # GPU monitoring
    htop              # process monitoring
    neovim

    # CLI tools
    wl-clipboard      # wl-copy/wl-paste (Claude Code reads pasted images with these)

    # Development
    gh                # GitHub CLI
  ];
}

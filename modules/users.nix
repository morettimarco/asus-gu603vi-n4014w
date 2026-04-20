  # CHANGEME: Replace CHANGEME_USERNAME with your Linux username
  # and CHANGEME_DESCRIPTION with your display name.
{ pkgs, ... }:

{
  users.users.CHANGEME_USERNAME = {
    isNormalUser = true;
    description = "CHANGEME_DESCRIPTION";
    extraGroups = [ "networkmanager" "wheel" "gamemode" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };
}

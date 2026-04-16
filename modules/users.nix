{ pkgs, ... }:

{
  users.users.marco = {
    isNormalUser = true;
    description = "Marco";
    extraGroups = [ "networkmanager" "wheel" "gamemode" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };
}

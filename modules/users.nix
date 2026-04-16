{ pkgs, ... }:

{
  users.users.marco = {
    isNormalUser = true;
    description = "Marco";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };
}

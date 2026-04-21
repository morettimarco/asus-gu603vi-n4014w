{ pkgs, ... }:

{
  # --- ASUS ROG daemon (fan profiles, keyboard LEDs, charge limit) ---
  services.asusd.enable = true;

  # --- GPU mode switching (hybrid / dedicated / integrated) ---
  services.supergfxd.enable = true;

  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  environment.systemPackages = with pkgs; [
    asusctl        # CLI for asusd (profiles, LEDs, etc.)
    supergfxctl    # CLI for GPU switching
  ];
}

{ pkgs, ... }:

let
  # WORKAROUND(asusd-aura-no-resume): see workarounds.json.
  # asusd never runs its keyboard resume task (the call is commented out
  # upstream), so nothing re-sends the LED mode after sleep. Setting LedMode
  # also re-applies asusd's stored brightness, which can be stale, so the live
  # value is written back afterwards. Brightness 0 is left alone: it is either
  # the user's choice or PowerDevil's idle blanking, which it undoes on input.
  auraReapply = pkgs.writeShellApplication {
    name = "aura-reapply";
    runtimeInputs = with pkgs; [ coreutils gnugrep systemd ];
    text = ''
      sleep 2  # let the keyboard's USB controller settle after resume
      aura=$(busctl --system --list tree xyz.ljones.Asusd | grep '^/xyz/ljones/aura/' | head -n1)
      brightness=$(busctl --system get-property xyz.ljones.Asusd "$aura" xyz.ljones.Aura Brightness | cut -d' ' -f2)
      mode=$(busctl --system get-property xyz.ljones.Asusd "$aura" xyz.ljones.Aura LedMode | cut -d' ' -f2)
      if [ "$brightness" = 0 ]; then
        echo "aura-reapply: brightness is 0, leaving it (mode $mode)"
        exit 0
      fi
      busctl --system set-property xyz.ljones.Asusd "$aura" xyz.ljones.Aura LedMode u "$mode"
      busctl --system set-property xyz.ljones.Asusd "$aura" xyz.ljones.Aura Brightness u "$brightness"
      echo "aura-reapply: re-sent mode $mode at brightness $brightness"
    '';
  };
in
{
  # --- ASUS ROG daemon (fan profiles, keyboard LEDs, charge limit) ---
  services.asusd.enable = true;

  # WORKAROUND(asusd-aura-no-resume): runs in sleep-actions.service on wake.
  # `|| true` because a failed LED refresh must not fail the unit's stop.
  powerManagement.resumeCommands = "${auraReapply}/bin/aura-reapply || true";

  # WORKAROUND(asus-shutdown-no-restart): see workarounds.json.
  # asus-shutdown is a long-running daemon that defers exit until the EC
  # shutdown write is safe — by design it ignores SIGTERM until real
  # shutdown.target, and the unit ships with SendSIGKILL=no so systemd
  # never escalates. nixos-rebuild's default restart-on-switch therefore
  # leaves a stuck old process in the cgroup, fails the new start with
  # "Will not start SendSIGKILL=no service ... while processes exist",
  # and the whole switch exits non-zero. Leave the running instance
  # alone across switches; it'll be picked up fresh on next boot.
  systemd.services.asus-shutdown = {
    restartIfChanged = false;
    stopIfChanged = false;
  };

  # --- GPU mode switching (hybrid / dedicated / integrated) ---
  # The upstream module already puts pciutils + kmod on the service PATH.
  services.supergfxd.enable = true;

  environment.systemPackages = with pkgs; [
    asusctl        # CLI for asusd (profiles, LEDs, etc.)
    supergfxctl    # CLI for GPU switching
  ];
}

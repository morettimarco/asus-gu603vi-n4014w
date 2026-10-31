{ pkgs, ... }:

{
  # --- M4 button: cycle ASUS aura keyboard effects ---
  # The M4 button on the Zephyrus emits XKB keycode 156 (= evdev KEY_PROG1 = 148).
  # actkbd binds raw evdev events to commands at the system level, independent
  # of the desktop environment, so this binding survives KDE config resets.
  services.actkbd = {
    enable = true;
    bindings = [
      {
        keys = [ 148 ];                    # KEY_PROG1 (M4)
        events = [ "key" ];
        command = "${pkgs.asusctl}/bin/asusctl aura effect --next-mode";
      }
    ];
  };
}

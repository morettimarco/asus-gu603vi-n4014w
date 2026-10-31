{ ... }:

# Optional: face login with the IR camera. Not imported by default; uncomment
# ./modules/laptop/howdy.nix in flake.nix to enable it, then enrol with
# `sudo howdy add`.
{
  services.howdy = {
    enable = true;

    # "sufficient" means face OR password: convenient, but a printed photo can
    # fool it. Use "required" for face AND password.
    control = "sufficient";

    settings.video = {
      # The IR camera on the GU603VI. Confirm with `ls /dev/v4l/by-path/`:
      # the by-path name survives /dev/videoN renumbering.
      device_path = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:7:1.2-video-index0";
      certainty = 4.5;
    };
  };

  # WORKAROUND(polkit-helper-howdy-camera)
  # polkit 127 runs its PAM helper in a sandboxed unit (PrivateDevices=yes,
  # DevicePolicy=strict), so pam_howdy can't open the IR camera. Its error
  # then derails the KDE agent's conversation and the password fallback fails
  # too. nixpkgs relaxes this for u2f/yubico/fprintd, not yet for howdy.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = [ "char-video4linux rw" ];
  };
}

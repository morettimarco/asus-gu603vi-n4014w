{ ... }:

{
  # --- Btrfs support ---
  boot.supportedFilesystems = [ "btrfs" ];

  # --- Snapper snapshot management ---
  services.snapper = {
    snapshotRootOnBoot = true;

    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "marco" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = "5";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "2";
        TIMELINE_LIMIT_YEARLY = "0";
      };

      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "marco" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = "5";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "2";
        TIMELINE_LIMIT_YEARLY = "0";
      };
    };
  };

  # TODO: Package and enable limine-snapper-sync to make snapshots
  # bootable from the Limine menu. For now, snapper creates and manages
  # snapshots independently — manual rollback via:
  #   snapper -c root list
  #   snapper -c root undochange <num1>..<num2>
}

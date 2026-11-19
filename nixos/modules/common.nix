# Shared system configuration for every machine.
# Machine-specific boot/GPU/hardware settings live in ../hosts/<host>/.
{ config, pkgs, ... }:

let
  # Orbital clock SDDM theme (https://github.com/Rizmi/orbital-clock-sddm),
  # the clockwork/orbital QML extracted from Ryoku - used standalone, no
  # Ryoku desktop involved. Vendored into the store like future-cursors;
  # SDDM discovers it via /run/current-system/sw/share/sddm/themes
  # (the sddm module sets pathsToLink "/share/sddm").
  orbital-sddm-theme = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "orbital-sddm-theme";
    version = "c5d7e33";
    src = pkgs.fetchFromGitHub {
      owner = "Rizmi";
      repo = "orbital-clock-sddm";
      rev = "c5d7e33bb3eb1aedfc675c54cddbbc38c062e545";
      hash = "sha256-fV68huEmZWARJHL4jv4N6GS6y4ZeKf9yWyjthBbzg+0=";
    };
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -r $src/orbital $out/share/sddm/themes/orbital
    '';
  };
in

{
  # ─── Graphics userspace (driver selection is per host) ───────────────────
  hardware.graphics.enable = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  # Display manager: COSMIC greeter (sole greeter; SDDM removed due to
  # conflict). The greeter's session menu lists every installed Wayland
  # session — COSMIC, Niri, and anything you enable later.
  systemd.services.display-manager.environment = {
    XCURSOR_PATH = "/run/current-system/sw/share/icons";
    XDG_DATA_DIRS = "/run/current-system/sw/share";
  };

  xdg.portal.wlr.settings.screencast = {
    chooser_type = "dmenu";
    chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -p 'Share:'";
    max_fps = 30;
  };

  # Recreate the Xcursor "default" theme (cosmic used to provide it) so the
  # SDDM/kwin greeter has a visible cursor.
  xdg.icons.fallbackCursorThemes = [ "Future-cursors" ];

  # ─── Networking, locale, user ────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."hydragon2000" = {
    isNormalUser = true;
    description = "hydragon2000";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    # allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "corefonts" ];
  };

  # Enables experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # For the curl install of opencode
  programs.nix-ld.enable = true;

  # ─── Desktop / compositor ────────────────────────────────────────────────
  # MANGO!
  programs.mango.enable = true;

  services.displayManager.defaultSession = "mango";

  # Display manager: SDDM with the Orbital clock theme. Note this is the
  # standalone Rizmi theme, NOT the Ryoku desktop.
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm; # the Qt6 build
    theme = "orbital";
    wayland.enable = true;
    # weston (SDDM's default greeter compositor) draws its cursor through a
    # hardware cursor plane that silently fails on the proprietary NVIDIA
    # driver - input works but the pointer is invisible. kwin_wayland has a
    # software-cursor fallback, verified on this machine.
    wayland.compositor = "kwin";
    extraPackages = with pkgs.kdePackages; [
      qtsvg
      qt5compat
      qtdeclarative
    ];
  };

  # ─── Services ────────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true; # Secret portal (Flatpak/app passwords)
  security.rtkit.enable = true;               # PipeWire realtime priority
  services.libinput.enable = true;            # touchpad udev rules
  # optional — keep only if you want them:
  services.accounts-daemon.enable = true;     # SDDM user list / avatars
  services.avahi.enable = true;               # mDNS / network printers

  # Flatpak enable
  services.flatpak.enable = true;

  # ─── Packages ────────────────────────────────────────────────────────────
  environment.systemPackages =
    with pkgs;
    let
      # Future dark cursor theme (https://github.com/yeyushengfan258/Future-cursors).
      # Source lives in future-cursors/dist; this packages it into the
      # nix store. home/common.nix references the same files for
      # home.pointerCursor - it is the same store path, nothing is duplicated.
      future-cursors = pkgs.runCommand "future-cursors" {
        preferLocalBuild = true;
        allowSubstitutes = false;
      } ''
        mkdir -p $out/share/icons
        cp -r ${../future-cursors/dist} $out/share/icons/Future-cursors
      '';
    in
    [
      future-cursors
      orbital-sddm-theme
      helix
      wget
      git
      ghostty
      curl
      fuzzel
      glib # gdbus, used by ~/.local/bin/mango-layout-osd
      ironbar
      brightnessctl
      python3
      rustc
      cargo
      nodejs
      gcc
      adwaita-icon-theme
      power-profiles-daemon
      noctalia
      udiskie
      xfconf
      gnome-themes-extra
      polkit_gnome
      lxsession
      lxappearance
      vlc
      btop
      onlyoffice-desktopeditors
      xwayland-satellite
      rio
    ];

  # ─── Fonts ───────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nerd-fonts.noto
    corefonts
  ];

  # ─── Hardware-independent services ───────────────────────────────────────
  services.upower.enable = true;

  services.power-profiles-daemon.enable = true;

  hardware.bluetooth.enable = true;

  services.dbus.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable Thunar and its essential volume/archive plugins
  programs.dconf.enable = true;
  programs.xfconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # Ensure USB drives automount properly without a desktop environment
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.udisks2.enable = true;

  # Optional: needed only if you want Noctalia's polkit agent / GUI auth prompts.
  security.polkit.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}

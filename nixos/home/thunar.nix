# Thunar theming & behavior — dark with blue accents + blue folder icons.
# Imported from home.nix. Pure Home-Manager: no git staging needed
# (/etc/nixos is not a git repo).
{ pkgs, ... }:

{
  # ─── 1. GTK look: dark base, blue accents ────────────────────────────────
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    # Papirus icons with BLUE folders — the nixpkgs package does this
    # natively at build time (papirus-folders -C blue), fully declarative.
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override { color = "blue"; };
    };

    # Palette: Catppuccin Mocha dark with its blue as the accent.
    gtk3.extraCss = ''
      /* Blue accents — used by selections, highlights, checks, etc. */
      @define-color accent_color #89b4fa;
      @define-color accent_bg_color #89b4fa;
      @define-color accent_fg_color #1e1e2e;

      /* Thunar chrome */
      .thunar toolbar { background-color: #1e1e2e; }
      .thunar .sidebar { background-color: #181825; }
      .thunar .sidebar row:selected {
        background-color: #313244;
        color: #89b4fa;
      }

      /* Disk-usage bars in the shortcuts pane (Thunar ≥ 4.21.3) */
      .thunar .disk-space-usage-bar { min-height: 8px; }
      .thunar .disk-space-usage-bar--normal {
        background: none;
        background-color: #89b4fa;
      }

      /* Icon view spacing */
      * {
        -ThunarAbstractIconView-row-spacing: 12;
        -ThunarAbstractIconView-column-spacing: 12;
      }
    '';
  };

  # ─── 2. Dark mode for Wayland portals & gtk apps ──────────────────────────
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    icon-theme = "Papirus-Dark";
  };

  # ─── 3. Declarative Thunar behavior via xfconf ────────────────────────────
  xfconf = {
    enable = true;
    settings.thunar = {
      "default-view" = "ThunarIconView";
      "misc-single-click" = false;
      "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";

      # Nice hidden settings (see the Thunar hidden-settings list)
      "misc-always-show-tabs" = false;
      "misc-confirm-close-multiple-tabs" = false;
      "misc-tab-close-middle-click" = true;
      "misc-small-toolbar-icons" = true;
      "misc-image-size-in-statusbar" = false; # high I/O — keep off
    };
  };
}

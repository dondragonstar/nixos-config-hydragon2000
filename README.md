# NixOS config — new machine guide

A modular NixOS + Home Manager setup. Every machine is described by a small
host folder; everything else is shared.

```text
flake.nix                    one entry per machine
modules/common.nix           shared system config
home/common.nix              shared Home Manager config (+ thunar.nix)
hosts/<hostname>/default.nix machine settings (hostname, timezone, GPU, boot)
hosts/<hostname>/hardware-configuration.nix   generated on that machine
dotfiles/                    raw config files for $HOME (not HM-managed)
```

Replace every `your_hostname` and `your_username` below with the real values.
Use the same name for both the hostname and the host folder.

---

## 1. Install NixOS

Install NixOS normally. The installer generates
`/etc/nixos/hardware-configuration.nix` for **this** machine — you will keep it.

Pick a username during install, or let the config create one later. Use the
**same** name for `your_username`; the config defines that account and gives it
`wheel` and `networkmanager`.

## 2. Clone this repo

```bash
git clone https://github.com/dondragonstar/nixos-config-hydragon2000.git ~/nixos-config
```

If the fresh install has no `git` yet:

```bash
nix-shell -p git --run \
  'git clone https://github.com/dondragonstar/nixos-config-hydragon2000.git ~/nixos-config'
```

## 3. Move the hardware file, then copy the config

```bash
sudo mkdir -p /etc/nixos/hosts/your_hostname
sudo mv /etc/nixos/hardware-configuration.nix \
        /etc/nixos/hosts/your_hostname/hardware-configuration.nix

sudo cp -a ~/nixos-config/nixos/. /etc/nixos/
```

If there is no `/etc/nixos/hardware-configuration.nix`, regenerate it:

```bash
sudo nixos-generate-config
```

## 4. Create the host file

```bash
sudo nano /etc/nixos/hosts/your_hostname/default.nix
```

(`hx` isn't installed until after the first switch — use `nano` here.)

Contents of `hosts/your_hostname/default.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Must match the flake attribute name in step 5.
  networking.hostName = "your_hostname";

  time.timeZone = "Asia/Kolkata";
  system.stateVersion = "26.05";   # the release this machine was installed with

  # Bootloader — use whatever the installer set up.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GPU: pick the one for this machine.
  #   Intel / generic : [ "modesetting" ]
  #   AMD             : [ "amdgpu" ]
  #   NVIDIA          : [ "nvidia" ]  + a hardware.nvidia block
  services.xserver.videoDrivers = [ "modesetting" ];
}
```

## 5. Register the host in flake.nix

Open `/etc/nixos/flake.nix` and look at the bottom:

```nix
nixosConfigurations = {
  nixos = mkHost { hostDir = "laptop"; username = "hydragon2000"; };
  # ...
};
```

**Delete the `nixos = mkHost { ... };` line.** It describes the original laptop
(NVIDIA, custom GRUB, Intel initrd) and must never be built on another machine.

Add your machine instead:

```nix
nixosConfigurations = {
  your_hostname = mkHost {
    hostDir  = "your_hostname";
    username = "your_username";
  };
};
```

Notes:

- The attribute name **must** equal `networking.hostName`; the `flakeswitch`
  helper resolves it with `--flake /etc/nixos#$(hostname)`.
- 32-bit ARM or other architectures: add `system = "aarch64-linux";`.
- The username is used everywhere automatically (`users.users.<name>`,
  `home.username`, `home.homeDirectory = /home/<name>`).

## 6. Build, then switch

Do **not** run `flakeswitch` yet: on a fresh install the hostname may still be
`nixos`, which would point at the wrong attribute.

```bash
cd /tmp
sudo nixos-rebuild build  --flake /etc/nixos#your_hostname
sudo nixos-rebuild switch --flake /etc/nixos#your_hostname
```

If the build fails, fix the errors before switching. `build` never activates
anything.

## 7. Set the account password

```bash
sudo passwd your_username
```

The account gets `wheel` and `networkmanager` groups automatically.

## 8. Install the dotfiles

These are plain files, not Home Manager-managed. Copy them and fix the paths
that still contain the original username:

```bash
cd ~/nixos-config

sudo rsync -a --chown=your_username:users dotfiles/.config/ /home/your_username/.config/
sudo rsync -a --chown=your_username:users dotfiles/.local/  /home/your_username/.local/

sudo sed -i 's|/home/hydragon2000|/home/your_username|g' \
  /home/your_username/.config/mango/config.conf \
  /home/your_username/.config/noctalia/config.toml
```

Then:

- Put wallpapers in `/home/your_username/Pictures/Wallpapers` (or edit the path
  in `noctalia/config.toml`).
- Make sure `~/.local/bin/mango-*` are executable (rsync preserves the mode).

## 9. Reboot

```bash
sudo reboot
```

Log in as `your_username`. Mango, Noctalia and the bar should come up.

## 10. Going forward

```bash
flakeswitch          # rebuild; on success, snapshot /etc/nixos into ~/nixos-config
cd ~/nixos-config
git commit -am "what changed"
git push             # after pointing origin at your own repo/fork
```

The clone still points at the original repo. To keep your own copy:

```bash
git remote set-url origin git@github.com:YOUR_ACCOUNT/YOUR_REPO.git
```

---

## Do not copy from another machine

| Thing | Why |
|---|---|
| `hardware-configuration.nix` | disk UUIDs, filesystems, CPU microcode |
| `hardware.nvidia.*`, bus IDs | specific to the original laptop's GPU |
| `boot.loader.grub.*` | bootloader type/device/EFI layout |
| `boot.initrd.kernelModules = [ "i915" ]` | Intel-specific |
| `system.stateVersion` | must match the release **this** machine was installed with |
| `~/.ssh`, browser profiles | private keys and personal data |

`system.stateVersion` is not a normal setting: it must be the release this
machine was **installed** with and should never be bumped afterwards. A wrong
value does not fail the build; it silently changes migration behaviour.

## Changing hostname or username later

- Hostname: `networking.hostName` in `hosts/<name>/default.nix` **and** the
  flake attribute name (they must stay equal).
- Username: the `username = "...";` argument in `flake.nix` only. Home
  directory and the NixOS account follow it. Moving an existing account's
  files is a manual `mv /home/old /home/new` + `chown` afterwards.

## Troubleshooting

- `does not provide attribute 'nixosConfigurations.<name>'` → the hostname and
  the flake attribute name differ.
- Build fails on `hardware.nvidia` → you copied the original laptop's GPU block.
- `result` symlink errors in `/etc/nixos` → build from `/tmp`, not from
  `/etc/nixos`.
- `nixos-publish: command not found` → the shell was started before the
  rebuild; open a new terminal (or run `~/.local/bin/nixos-publish`).
- `dotnix host` always opens `hosts/laptop/default.nix` → use
  `sudo hx /etc/nixos/hosts/your_hostname/default.nix` on other machines.

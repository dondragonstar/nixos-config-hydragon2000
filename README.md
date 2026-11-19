# Snapshot repository

This repo is a **snapshot** of the live NixOS configuration plus a few dotfiles.
The working tree stays at `/etc/nixos`; this repo is for versioning, backup, and
bootstrapping other machines.

- `nixos/` — exact copy of `/etc/nixos` (a complete, buildable flake)
- `dotfiles/` — copies of selected files from `$HOME`
- `scripts/publish.sh` — refreshes both and stages the result

`nixos/` and `dotfiles/` are **outputs**. Don't edit them directly — the next
publish overwrites/deletes anything that isn't in `/etc/nixos` or `$HOME`.

## Daily workflow

Edit and rebuild as usual:

```bash
flakeswitch
```

`flakeswitch` is a shell function that runs

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

and, **only if that succeeds**, runs `nixos-publish`, which copies
`/etc/nixos` to `nixos/` and your dotfiles to `dotfiles/`, then `git add -A`.

Then, whenever you feel like it:

```bash
cd ~/nixos-config
git diff --cached          # review
git commit -m "Update config"
git push                   # after adding a remote
```

If a rebuild fails, nothing is copied — the repo keeps the last config that
actually built.

Dotfile-only changes do not trigger a rebuild, so publish them by hand:

```bash
nixos-publish
```

## One-time setup

```bash
cd ~/nixos-config
git config user.name  "Your Name"
git config user.email "you@example.com"
git remote add origin git@github.com:YOUR_USER/YOUR_REPO.git
git push -u origin main
```

## Building straight from the repo

`nixos/` is a standalone flake, so this works too (useful to test the snapshot):

```bash
nixos-rebuild build --flake ~/nixos-config/nixos#nixos
```

## Reusing this on another machine (including someone else's)

Usernames are **per host**, not hardcoded. Each machine is described by:

- `nixos/hosts/<name>/default.nix` — hostname, timezone, GPU, bootloader, `stateVersion`
- `nixos/hosts/<name>/hardware-configuration.nix` — generated on that machine
- one line in `nixos/flake.nix` — `hostDir` + `username`

**Rule:** the flake attribute must match `networking.hostName`, because
`flakeswitch` runs `nixos-rebuild ... --flake /etc/nixos#$(hostname)`.

### Steps on the new machine

```bash
# 1. Install NixOS, then:
git clone https://github.com/dondragonstar/nixos-config-hydragon2000.git ~/nixos-config
sudo cp -a ~/nixos-config/nixos/. /etc/nixos/

# 2. Replace the hardware file with THIS machine's generated one
sudo cp /etc/nixos/hardware-configuration.nix ~/hw.backup   # keep the installer's file
sudo cp /path/to/installer/hardware-configuration.nix ~/nixos-config/nixos/hosts/<name>/
#    (or re-run `nixos-generate-config --show-hardware-config`)

# 3. Create hosts/<name>/default.nix  (see template below)

# 4. Add the host to flake.nix
#    <hostname> = mkHost { hostDir = "<name>"; username = "<user>"; };

# 5. Build, then switch
nixos-rebuild build  --flake /etc/nixos#<hostname>
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# 6. Give the account a password
sudo passwd <user>
```

Template for `hosts/<name>/default.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "friend";        # must equal the flake attribute name
  time.timeZone = "Asia/Kolkata";
  system.stateVersion = "26.05";         # the release when THIS machine was installed

  # Bootloader of this machine (installer default here):
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GPU of this machine. Do NOT copy the laptop's NVIDIA block.
  services.xserver.videoDrivers = [ "modesetting" ];  # or "amdgpu"/"nvidia"
}
```

Keep out of the new host file: `hardware.nvidia.*`, NVIDIA bus IDs, the
laptop's GRUB block, `boot.initrd.kernelModules = [ "i915" ]`, its hostname,
timezone, and `stateVersion`.

### Dotfiles for the new user

`dotfiles/` is not managed by Home Manager, so copy it and fix the paths that
contain your username:

```bash
sudo rsync -a --chown=<user>:users dotfiles/.config/ /home/<user>/.config/
sudo rsync -a --chown=<user>:users dotfiles/.local/  /home/<user>/.local/
sudo sed -i 's|/home/hydragon2000|/home/<user>|g' \
  /home/<user>/.config/mango/config.conf \
  /home/<user>/.config/noctalia/config.toml
```

Also fix the wallpaper path in Noctalia and copy wallpapers if you want them.
Do not copy `~/.ssh`, browser profiles, or anything personal.

Never copy another machine's `hardware-configuration.nix`, NVIDIA bus IDs,
bootloader device, or `system.stateVersion` wholesale.

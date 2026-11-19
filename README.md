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

## Reusing this on another machine

1. Install NixOS on the new machine.
2. Clone this repo to `~/nixos-config`.
3. Copy `~/nixos-config/nixos/` to `/etc/nixos` (or edit `/etc/nixos` and let
   `flakeswitch` fill the repo).
4. Replace `nixos/hosts/laptop/hardware-configuration.nix` with the new
   machine's **own** generated file, and add a host folder + flake attribute
   as described in `nixos/README.md`.
5. Copy the dotfiles from `dotfiles/` into `$HOME` (after wiring them into
   Home Manager, see `nixos/README.md`).

Never copy another machine's `hardware-configuration.nix`, NVIDIA bus IDs,
bootloader device, or `system.stateVersion` wholesale.

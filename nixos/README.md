# NixOS configuration

Shared configuration lives in `modules/common.nix` and `home/common.nix`.
Machine-specific settings live under `hosts/<machine>/`.

## Current machine

`hosts/laptop/` contains the NVIDIA/Intel laptop settings and its generated
`hardware-configuration.nix`. The flake attribute is still named `nixos`, so
this keeps working:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## Adding another machine

1. Install NixOS on the new machine.
2. Copy its generated `/etc/nixos/hardware-configuration.nix` into
   `/etc/nixos/hosts/<machine>/hardware-configuration.nix`.
3. Create `/etc/nixos/hosts/<machine>/default.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "desktop";
  time.timeZone = "Asia/Kolkata";
  system.stateVersion = "26.05"; # use the release the machine was installed with

  # Machine-specific GPU/boot settings, for example:
  # services.xserver.videoDrivers = [ "amdgpu" ];
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
```

4. Add it to the flake:

```nix
nixosConfigurations.desktop = mkHost { hostDir = "desktop"; };
```

5. Build and switch:

```bash
sudo nixos-rebuild build  --flake /etc/nixos#desktop
sudo nixos-rebuild switch --flake /etc/nixos#desktop
```

Never copy another machine's `hardware-configuration.nix`, NVIDIA bus IDs,
bootloader device, or `system.stateVersion` wholesale.

# NixOS Setup for Luckfox Pico Serial and ADB Access

## Quick Setup

Add this to your `/etc/nixos/configuration.nix`:

```nix
{
  # Add your user to dialout and plugdev groups for serial and ADB access
  users.users.YOUR_USERNAME.extraGroups = [ "dialout" "plugdev" ];

  # Udev rules for Luckfox Pico - Serial and ADB
  services.udev.extraRules = ''
    # Common USB-to-serial adapters (FTDI, CH340, CP210x, Prolific)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", MODE="0666", GROUP="dialout"

    # Rockchip devices (Luckfox RV1103) - Serial
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2207", MODE="0666", GROUP="dialout"

    # Rockchip devices (Luckfox RV1103) - ADB
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0006", SYMLINK+="android_adb"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0006", SYMLINK+="android%n"

    # Generic USB serial devices (fallback)
    KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
    KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
  '';
}
```

Replace `YOUR_USERNAME` with your actual username.

## Apply Changes

```bash
sudo nixos-rebuild switch
```

After rebuild, logout and login for group changes to take effect.

## Verify Setup

Check if you're in the required groups:
```bash
groups | grep -E 'dialout|plugdev'
```

Find your serial device:
```bash
ls -l /dev/ttyUSB* /dev/ttyACM*
```

Check ADB connection:
```bash
adb devices
```

## Connect to Device

### Serial Console (recommended for development)

Using minicom:
```bash
minicom -D /dev/ttyUSB0 -b 115200
```

Using screen:
```bash
screen /dev/ttyUSB0 115200
```

Using picocom:
```bash
picocom /dev/ttyUSB0 -b 115200
```

### ADB

List connected devices:
```bash
adb devices
```

Connect to shell:
```bash
adb shell
```

### SSH (requires network setup)

Buildroot:
```bash
ssh root@<ip>  # password: luckfox
```

Ubuntu:
```bash
ssh pico@<ip>  # password: luckfox
```

## Alternative: Home Manager

If you use Home Manager, you can also add the groups there:

```nix
{
  home.username = "YOUR_USERNAME";

  # This still needs to be in system configuration
  # but can reference it from home-manager
}
```

Note: udev rules and group membership must still be in system configuration, not Home Manager.

## Flake-based NixOS

If you use flakes for your NixOS config, add the same configuration to your system module.

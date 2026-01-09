#!/usr/bin/env bash
# Setup script for Luckfox Pico serial and ADB access
# Supports: Fedora Silverblue, NixOS, and standard Linux distros

set -e

echo "Luckfox Pico Serial and ADB Access Setup"
echo "========================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
else
    OS_ID="unknown"
fi

echo "Detected OS: $OS_ID"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root/sudo"
    echo "The script will ask for sudo when needed"
    exit 1
fi

# Function to add user to required groups
add_user_to_groups() {
    local REBOOT_MSG="$1"
    local GROUPS_ADDED=0

    # Check dialout group
    if groups | grep -q dialout; then
        echo "User $USER is already in dialout group ✓"
    else
        echo "Adding user $USER to dialout group..."
        sudo usermod -aG dialout "$USER"
        GROUPS_ADDED=1
    fi

    # Check plugdev group (for ADB)
    if groups | grep -q plugdev; then
        echo "User $USER is already in plugdev group ✓"
    else
        echo "Adding user $USER to plugdev group..."
        sudo usermod -aG plugdev "$USER"
        GROUPS_ADDED=1
    fi

    if [ $GROUPS_ADDED -eq 1 ]; then
        echo ""
        echo "IMPORTANT: $REBOOT_MSG"
        echo "After that, verify with: groups | grep -E 'dialout|plugdev'"
    fi
}

case "$OS_ID" in
    "fedora")
        # Check if it's Silverblue/Kinoite/etc (immutable)
        if grep -q "silverblue\|kinoite\|sericea" /etc/os-release 2>/dev/null || command -v rpm-ostree &> /dev/null; then
            echo "Detected Fedora Silverblue/immutable variant"
            echo ""
            echo "Installing udev rules..."
            sudo cp 99-luckfox-serial.rules /etc/udev/rules.d/
            sudo udevadm control --reload-rules
            sudo udevadm trigger
            echo "Udev rules installed ✓"
            echo ""

            add_user_to_groups "On Silverblue, you must REBOOT for group changes to take effect!"
        else
            # Standard Fedora
            echo "Standard Fedora detected"
            echo ""
            echo "Installing udev rules..."
            sudo cp 99-luckfox-serial.rules /etc/udev/rules.d/
            sudo udevadm control --reload-rules
            sudo udevadm trigger
            echo "Udev rules installed ✓"
            echo ""

            add_user_to_groups "You must logout and login for group changes to take effect!"
        fi
        ;;

    "nixos")
        echo "NixOS detected - manual configuration required"
        echo ""
        echo "Add the following to your /etc/nixos/configuration.nix:"
        echo ""
        echo "----------------------------------------"
        cat << 'EOF'
  # Luckfox Pico serial and ADB access
  users.users.YOUR_USERNAME.extraGroups = [ "dialout" "plugdev" ];

  services.udev.extraRules = ''
    # Common USB-to-serial adapters
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", MODE="0666", GROUP="dialout"

    # Rockchip devices (Luckfox) - Serial
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2207", MODE="0666", GROUP="dialout"

    # Rockchip devices (Luckfox) - ADB
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0006", SYMLINK+="android_adb"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="0006", SYMLINK+="android%n"

    # Generic USB serial devices
    KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
    KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
  '';
EOF
        echo "----------------------------------------"
        echo ""
        echo "Then rebuild your system:"
        echo "  sudo nixos-rebuild switch"
        echo ""
        ;;

    *)
        # Standard Linux distro
        echo "Standard Linux distribution"
        echo ""
        echo "Installing udev rules..."
        sudo cp 99-luckfox-serial.rules /etc/udev/rules.d/
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        echo "Udev rules installed ✓"
        echo ""

        add_user_to_groups "You must logout and login for group changes to take effect!"
        ;;
esac

echo ""
echo "Setup complete!"
echo ""
echo "To connect to the device:"
echo "  Serial Console (recommended for development):"
echo "    minicom -D /dev/ttyUSB0 -b 115200"
echo "    screen /dev/ttyUSB0 115200"
echo "    picocom /dev/ttyUSB0 -b 115200"
echo ""
echo "  ADB:"
echo "    adb devices"
echo "    adb shell"
echo ""
echo "Find serial device: ls -l /dev/ttyUSB* /dev/ttyACM*"
echo "Check ADB: adb devices"

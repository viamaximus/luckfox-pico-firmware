{
  description = "dev environment for luckfox pico mini b (RV1103)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "luckfox-pico-dev";

          buildInputs = with pkgs; [
            # cross-compilation toolchain for arm cortex-a7
            pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
            pkgsCross.armv7l-hf-multiplatform.buildPackages.binutils

            # sdk build dependencies (from luckfox sdk docs)
            # compilers and build tools
            gcc
            gnumake
            cmake
            ninja
            pkg-config
            autoconf
            automake
            libtool
            gperf

            # required sdk tools
            expect
            gawk
            texinfo
            openssl
            openssl.dev
            bison
            flex
            fakeroot
            bc
            cpio
            ncurses
            ncurses.dev

            # development utilities
            git
            curl
            wget
            unzip
            zip
            which

            # flash and debug tools
            dtc # device tree compiler
            ubootTools # mkimage and other U-Boot tools
            android-tools # adb and fastboot

            # serial communication
            minicom
            screen
            picocom

            # network tools
            openssh
            rsync

            # python for scripting
            python3
            python3Packages.pyserial

            # additional useful tools
            neovim
            tmux
            htop
            file
            patchelf
          ];

          shellHook = ''
            echo "Luckfox Pico Mini B Development Environment"
            echo "============================================"
            echo "Board: Luckfox Pico Mini B"
            echo "SoC: RV1103 (ARM Cortex-A7 @ 1.2GHz)"
            echo "Memory: 64MB DDR2 | Storage: 128MB SPI NAND"
            echo ""
            echo "SDK Build Dependencies:"
            echo "  - All packages from Luckfox SDK documentation included"
            echo "  - Buildroot, U-Boot, and Linux kernel build tools"
            echo "  - Device tree compiler, image packaging utilities"
            echo ""
            echo "Available Tools:"
            echo "  - ARM cross-compiler: armv7l-unknown-linux-gnueabihf-gcc"
            echo "  - Build: make, cmake, ninja, gperf, expect"
            echo "  - Serial: minicom, screen, picocom"
            echo "  - ADB: adb, fastboot"
            echo "  - Device Tree: dtc"
            echo "  - U-Boot: mkimage"
            echo ""
            echo "SDK Usage:"
            echo "  - Clone SDK: git clone https://github.com/LuckfoxTECH/luckfox-pico.git"
            echo "  - Build: ./build.sh lunch && ./build.sh"
            echo "  - Configure buildroot: ./build.sh buildrootconfig"
            echo ""
            echo "Cross-compilation environment:"
            echo "  CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-"
            echo "  ARCH=arm"
            echo ""

            # Set up cross-compilation environment variables
            export CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-
            export ARCH=arm
            export CC=''${CROSS_COMPILE}gcc
            export CXX=''${CROSS_COMPILE}g++
            export AR=''${CROSS_COMPILE}ar
            export AS=''${CROSS_COMPILE}as
            export LD=''${CROSS_COMPILE}ld
            export STRIP=''${CROSS_COMPILE}strip

            # Helpful aliases
            alias minicom-luckfox='minicom -D /dev/ttyUSB0 -b 115200'
            alias screen-luckfox='screen /dev/ttyUSB0 115200'

            echo "Device Connection:"
            echo "  Serial Console:"
            echo "    - minicom-luckfox  (or: minicom -D /dev/ttyUSB0 -b 115200)"
            echo "    - screen-luckfox   (or: screen /dev/ttyUSB0 115200)"
            echo "    - picocom /dev/ttyUSB0 -b 115200"
            echo "  ADB:"
            echo "    - adb devices"
            echo "    - adb shell"
            echo "  SSH (requires network setup):"
            echo "    - ssh root@<ip>  (Buildroot, password: luckfox)"
            echo "    - ssh pico@<ip>  (Ubuntu, password: luckfox)"
            echo ""
            echo "Setup Required:"
            if [ -f /etc/NIXOS ]; then
              echo "  NixOS - See NIXOS-SETUP.md for configuration"
              echo "  Add dialout and plugdev groups + udev rules to configuration.nix"
            else
              echo "  Run: ./setup-serial.sh"
              echo "  (Installs udev rules and adds you to dialout/plugdev groups)"
            fi
            echo ""

            # Check if user is in required groups
            MISSING_GROUPS=""
            if ! groups | grep -q dialout; then
              MISSING_GROUPS="dialout"
            fi
            if ! groups | grep -q plugdev; then
              if [ -n "$MISSING_GROUPS" ]; then
                MISSING_GROUPS="$MISSING_GROUPS, plugdev"
              else
                MISSING_GROUPS="plugdev"
              fi
            fi

            if [ -z "$MISSING_GROUPS" ]; then
              echo "Status: User is in dialout and plugdev groups ✓"
            else
              echo "Warning: User is NOT in required groups: $MISSING_GROUPS"
              echo "         Serial/ADB access may fail - run ./setup-serial.sh"
            fi
            echo ""
          '';
        };
      }
    );
}

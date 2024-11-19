{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Define supported systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Function to get packages for a specific system
        getPkgs = stdenv: let
          cpppkgs = pkgs;
        in {
          inherit pkgs cpppkgs stdenv;
        };

        # Package definition
        uvgrtp = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./default.nix {
          inherit stdenv;
        };

        # Get package sets for different compilers
        gccPkgs = getPkgs (pkgs.gcc14Stdenv or pkgs.gcc13Stdenv);
        clangPkgs = getPkgs (
          if system == "aarch64-darwin" || system == "x86_64-darwin"
          then pkgs.llvmPackages_16.libcxxStdenv
          else pkgs.llvmPackages_19.libcxxStdenv
        );

        # Build variants with different stdenvs
        mkVariant = pkgSet: {
          uvgrtp = uvgrtp {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
        };

        # Development shell dependencies
        commonDevPackages = with pkgs; [
          # Build tools
          cmake
          ninja
          pkg-config

          # Compilers and development tools
          gcc
          clang
          clang-tools

          # Debugging and profiling
          gdb
          lldb
          valgrind
        ];

        # System-specific packages
        systemSpecificPackages = with pkgs;
          if system == "x86_64-linux" || system == "aarch64-linux" then [
            # Linux-specific packages
            linuxPackages.perf
            strace
            ltrace
          ] else if system == "x86_64-darwin" || system == "aarch64-darwin" then [
            # macOS-specific packages
            darwin.apple_sdk.frameworks.SystemConfiguration
            darwin.apple_sdk.frameworks.CoreFoundation
          ] else [];

      in {
        packages = {
          default = (mkVariant gccPkgs).uvgrtp;
          gccUvgRTP = (mkVariant gccPkgs).uvgrtp;
          clangUvgRTP = (mkVariant clangPkgs).uvgrtp;
        };

        devShells = {
          default = pkgs.mkShell {
            name = "uvgrtp-dev";

            packages = commonDevPackages ++ systemSpecificPackages;

            # Environment variables
            shellHook = ''
              export PS1="\[\033[1;34m\][uvgrtp-dev:\w]$\[\033[0m\] "

              # Set up compilation flags
              export CFLAGS="-Wall -Wextra -g -O2"
              export CXXFLAGS="$CFLAGS -std=c++17"

              # Set up pkg-config path
              export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${pkgs.pkg-config}/lib/pkgconfig"

              echo "Welcome to UvgRTP development environment!"
              echo "Available tools:"
              echo "  - Build: cmake, ninja, make"
              echo "  - Compilers: gcc, clang"
              echo "  - Analysis: clang-tidy"
              echo "  - Debug: gdb, lldb, valgrind"
            '';

            # Include build inputs from the main package
            inputsFrom = [ self.packages.${system}.default ];
          };

          # GCC-specific development shell
          gcc = pkgs.mkShell {
            name = "uvgrtp-gcc-dev";

            packages = commonDevPackages ++ systemSpecificPackages;

            shellHook = ''
              export PS1="\[\033[1;32m\][uvgrtp-gcc:\w]$\[\033[0m\] "
              export CC=gcc
              export CXX=g++
              export CFLAGS="-Wall -Wextra -g -O2"
              export CXXFLAGS="$CFLAGS -std=c++17"

              echo "GCC-specific development environment activated"
            '';

            inputsFrom = [ self.packages.${system}.gccUvgRTP ];
          };

          # Clang-specific development shell
          clang = pkgs.mkShell {
            name = "uvgrtp-clang-dev";

            packages = commonDevPackages ++ systemSpecificPackages;

            shellHook = ''
              export PS1="\[\033[1;35m\][uvgrtp-clang:\w]$\[\033[0m\] "
              export CC=clang
              export CXX=clang++
              export CFLAGS="-Wall -Wextra -g -O2"
              export CXXFLAGS="$CFLAGS -std=c++17"

              echo "Clang-specific development environment activated"
            '';

            inputsFrom = [ self.packages.${system}.clangUvgRTP ];
          };
        };
      }
    );
}

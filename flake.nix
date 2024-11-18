{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        getPkgs = stdenv: let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          cpppkgs = pkgs;
        in {
          inherit pkgs cpppkgs stdenv;
        };

        uvgrtp = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./default.nix {
          inherit stdenv;
        };

        # Get package sets for different compilers
        gccPkgs = getPkgs nixpkgs.legacyPackages.x86_64-linux.gcc14Stdenv;
        clangPkgs = getPkgs nixpkgs.legacyPackages.x86_64-linux.llvmPackages_19.libcxxStdenv;

        # Build variants with different stdenvs
        mkVariant = pkgSet: {
          uvgrtp = uvgrtp {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
        };

      in
      {
        default = (mkVariant gccPkgs).uvgrtp;

        # GCC variants
        gccUvgRTP = (mkVariant gccPkgs).uvgrtp;
        # Clang variants
        clangUvgRTP = (mkVariant clangPkgs).uvgrtp;
      };
  };
}

{
  description = "atlas-cardano";
  # using the newest haskell.nix breaks when building postgresql-libpq-configure 0.11
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix?rev=d0b7bc42579a187e4753e459ef77dba6a1e9629e";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.CHaP = {
      url = "github:intersectmbo/cardano-haskell-packages?ref=repo";
      flake = false;
    };
  outputs = { self, nixpkgs, flake-utils, haskellNix, CHaP }:
    let
      supportedSystems = [
        "x86_64-linux"	"x86_64-darwin"	"aarch64-darwin"
      ];
    in
      flake-utils.lib.eachSystem supportedSystems (system:
      let
        overlay = final: prev: {
          haskell-nix = prev.haskell-nix // {
            extraPkgconfigMappings = prev.haskell-nix.extraPkgconfigMappings // {
                # String pkgconfig-depends names are mapped to lists of Nixpkgs
                # package names
                "libblst" = [ "blst" ];
            };
          };
        };

        overlays = [ haskellNix.overlay
          (final: prev: {
            hixProject =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc96";
                # This is used by `nix develop .` to open a shell for use with
                # `cabal`, `hlint` and `haskell-language-server`
                shell.tools = {
                  cabal = {};
                  hlint = {};
                  haskell-language-server = {};
                };
                # Non-Haskell shell tools go here
                shell.buildInputs = with pkgs; [
                  nixpkgs-fmt
                ];
                inputMap = { "https://chap.intersectmbo.org/" = CHaP; };
              };
          })
          overlay
        ];
        pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
        flake = pkgs.hixProject.flake {};
      in flake // {
        legacyPackages = pkgs;
      });
}

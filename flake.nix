{
  description = "ICFPC 2024";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    ocaml-overlay = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ocaml-overlay }@inputs:
    (
      let
        forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
      in
      {
        devShell = forAllSystems
          (system:
            let
              pkgs = import nixpkgs { inherit system; overlays = [ ocaml-overlay.overlays.default ]; };
              ocamlDeps = with pkgs.ocaml-ng.ocamlPackages_latest; [
                ocaml
                ocaml-lsp
                dune
                utop
                ocp-indent
		dream
		dream-html
		caqti-driver-postgresql
                ppx_deriving
              ];
            in
            pkgs.mkShell {
              buildInputs = ocamlDeps ++ [ pkgs.entr ];
              shellHook = ''
                export OCAMLRUNPARAM=b
              '';
            }
          );
      }
    );
}

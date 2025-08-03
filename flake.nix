{
  description = "Purcellimages.com";

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
        withDepsAndPkgs = f: forAllSystems (system:
            let
              pkgs = import nixpkgs { inherit system; overlays = [ ocaml-overlay.overlays.default ]; };
              ocamlPackages = pkgs.ocaml-ng.ocamlPackages_latest;
              ocamlDeps = with ocamlPackages; [
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
            in f pkgs ocamlPackages ocamlDeps
           );
      in
      {
        devShell = withDepsAndPkgs (pkgs: ocamlPackages: ocamlDeps:
            pkgs.mkShell {
              buildInputs = ocamlDeps ++ [ pkgs.entr ];
              shellHook = ''
                export OCAMLRUNPARAM=b
              '';
            }
        );

        defaultPackage = withDepsAndPkgs (pkgs: ocamlPackages: ocamlDeps:
          ocamlPackages.buildDunePackage {
            pname = "purcellimages";
            version = "";
            src = ./.;
            propagatedBuildInputs = ocamlDeps;
          }
        ); 
      }
    );
}

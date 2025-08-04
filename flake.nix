{
  description = "Purcellimages.com";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  nixConfig = {
    extra-substituters = "https://purcellimages.cachix.org";
    extra-trusted-public-keys = "purcellimages.cachix.org-1:nt4djy3HAPOP/kGqQRC7poriLCD23nkUG+37OxeVtR8=";
  };

  outputs = { self, nixpkgs }@inputs:
    (
      let
        forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
        withDepsAndPkgs = f: forAllSystems (system:
            let
              pkgs = import nixpkgs { inherit system; };
              ocamlPackages = pkgs.ocamlPackages;
              ocamlDeps = (with ocamlPackages; [
                ocaml
                dune_3
		dream
		dream-html
		caqti-driver-postgresql
                ppx_deriving
                lwt_ppx
              ]);
            in f pkgs ocamlPackages ocamlDeps
           );
      in
      {
        devShell = withDepsAndPkgs (pkgs: ocamlPackages: ocamlDeps:
            pkgs.mkShell {
              buildInputs = ocamlDeps ++ [ pkgs.entr ] ++ (with ocamlPackages; [ utop ocaml-lsp ocp-indent ]);
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
            buildInputs = ocamlDeps;
          }
        ); 
      }
    );
}

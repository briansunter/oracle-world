{
  description = "OCI Always Free Tier — IaC with OpenTofu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Infrastructure
              opentofu
              oci-cli
              just

              # Utilities
              jq
              shellcheck
              shfmt
              tflint
            ];

            shellHook = ''
              if [[ -z "''${DIRENV_IN_ENVRC:-}" ]]; then
                echo "OCI Always Free Tier Dev Shell"
                echo ""
                echo "Commands:"
                echo "  just setup    # Auto-discover OCI config"
                echo "  just plan     # Preview changes"
                echo "  just apply    # Deploy infrastructure"
                echo ""
              fi
            '';
          };
        }
      );
    };
}

{
  description = "C Compiler";
  inputs = {
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = {
    self,
    git-hooks,
    nixpkgs,
  }: let
    supportSystems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportSystems;
  in {
    checks = forAllSystems (system: {
      pre-commit-check = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra = {
            enable = true;
            settings.verbosity = "quiet";
          };
          shfmt.enable = true;
          clang-format.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };
    });
    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (self.checks.${system}.pre-commit-check.config) package configFile;
    in
      pkgs.writeShellScriptBin "pre-commit-run" ''
        ${pkgs.lib.getExe package} run --all-files --config ${configFile}
      '');
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
    in {
      default = pkgs.mkShell {
        buildInputs = enabledPackages;
        inherit shellHook;
        packages = with pkgs; [
          gnumake
          glibc.static
          clang-tools
          bear
        ];
      };
    });
  };
}

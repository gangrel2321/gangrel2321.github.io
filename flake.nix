{
  description = "Jekyll / GitHub Pages dev environment for gangrel2321.github.io";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # github-pages ~> 232 pins jekyll 3.10; Ruby 3.3 is the safe pairing
        # (3.4 drops stdlib gems some old deps still expect).
        ruby = pkgs.ruby_3_3;

        # `serve` — one command to install gems (first run) and start the
        # local server with live-reload. Works inside `nix develop` (inherits
        # the shell's ruby/bundler + env) and via `nix run`.
        serve = pkgs.writeShellScriptBin "serve" ''
          if [ ! -d "''${BUNDLE_PATH:-.bundle/vendor}" ]; then
            echo "Installing gems (first run, one-time)..."
            bundle install || exit 1
          fi
          exec bundle exec jekyll serve --livereload --host 127.0.0.1 "$@"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            ruby
            pkgs.bundler
            serve
            # native deps for gems that compile C extensions (nokogiri, ffi, ...)
            pkgs.gcc
            pkgs.gnumake
            pkgs.pkg-config
            pkgs.libxml2
            pkgs.libxslt
            pkgs.zlib
            pkgs.openssl
          ];

          shellHook = ''
            # Jekyll's old Sass converter reads files as US-ASCII unless the
            # locale is UTF-8, which crashes on any non-ASCII char (em-dash,
            # curly quote). A bare Nix shell has no locale set, so pin one.
            export LANG="C.UTF-8"
            export LC_ALL="C.UTF-8"

            # Keep all gems inside the project so nothing touches your system.
            export BUNDLE_PATH="$PWD/.bundle/vendor"
            export BUNDLE_BIN="$PWD/.bundle/bin"
            export GEM_HOME="$BUNDLE_PATH"
            export PATH="$BUNDLE_BIN:$PATH"

            # Build nokogiri against the Nix system libraries rather than its
            # vendored copies (faster, and avoids the musl-locked gem).
            bundle config --local build.nokogiri --use-system-libraries >/dev/null 2>&1

            echo "Ruby $(ruby --version)"
            echo ""
            echo "Run:      serve        # installs gems if needed, then starts the server"
            echo "View at:  http://localhost:4000"
          '';
        };

        # Lets you skip the shell entirely: `nix run` from the repo root.
        apps.default = {
          type = "app";
          program = "${serve}/bin/serve";
        };
      });
}

{
  description = "Logos Blockchain Rapidsnark";

  # Some Windows consumers (e.g. LEZ) require logos-nix's MinGW.
  inputs.logos-nix.url = "github:logos-co/logos-nix";
  inputs.self.submodules = true;

  outputs =
    { self, logos-nix, ... }:
    let
      buildPkgs = logos-nix.legacyPackages.x86_64-linux;
      windowsPkgs = buildPkgs.pkgsWindows;
      lib = buildPkgs.lib;

      # Reads GMP's version and hash from build_gmp.sh, so the two can't drift apart.
      fetchGmp =
        let
          script = builtins.readFile ./build_gmp.sh;
          read = var: builtins.head (builtins.match ''.*${var}="?([^"[:space:]]+).*'' script);
          # Nix's GNU mirror list, not build_gmp.sh's. The hash pins the file either way.
          fetchUrl = "mirror://gnu/gmp/${read "GMP_NAME"}.tar.xz";
          hash = read "GMP_SHA256";
        in
        buildPkgs.fetchurl {
          url = fetchUrl;
          sha256 = hash;
        };

      version = lib.removeSuffix "\n" (builtins.readFile ./VERSION);
      versionHashes =
        (builtins.fromJSON (builtins.readFile ./rapidsnark-nix-hashes.json)).${version}
          or (throw "rapidsnark-nix-hashes.json has no hashes for ${version}. The release workflow adds them.");
      releaseUrl = "https://github.com/logos-blockchain/logos-blockchain-rapidsnark/releases/download/${version}";

      # Package name -> release archive platform.
      archivePlatforms = {
        linux-x86_64 = "linux-x86_64";
        linux-arm64 = "linux-arm64";
        macos-arm64 = "macOS-arm64";
        macos-x86_64 = "macOS-x86_64";
        windows-x86_64 = "windows-x86_64";
      };

      # Build machine -> package for that machine.
      hostPackages = {
        x86_64-linux = "linux-x86_64";
        aarch64-linux = "linux-arm64";
        aarch64-darwin = "macos-arm64";
        x86_64-darwin = "macos-x86_64";
      };

      # Downloads a release archive. Its contents are installed as they are.
      fetchRelease =
        system: name:
        let
          pkgs = logos-nix.legacyPackages.${system};
          platform = archivePlatforms.${name};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "rapidsnark-${name}";
          inherit version;
          src = pkgs.fetchurl {
            url = "${releaseUrl}/rapidsnark-${platform}-${version}.tar.gz";
            hash = versionHashes.${platform} or (throw "rapidsnark ${version} has no ${platform} archive.");
          };
          dontConfigure = true;
          dontBuild = true;
          dontFixup = true;
          installPhase = "cp -r . $out";
        };

      windowsSource = windowsPkgs.stdenv.mkDerivation {
        pname = "rapidsnark-windows-x86_64-source";
        version = self.shortRev or "dirty";
        src = self;

        # Prefetch gmp so we can build GMP without network (during build)
        gmp = fetchGmp;

        depsBuildBuild = [ buildPkgs.stdenv.cc ];
        nativeBuildInputs = [
          buildPkgs.cmake
          buildPkgs.gnumake
          buildPkgs.m4
        ];
        buildInputs = [
          windowsPkgs.windows.mcfgthreads
          windowsPkgs.windows.pthreads
        ];

        # We don't want to use cmake's configure step, the Makefile already does everything.
        dontUseCmakeConfigure = true;

        buildPhase = ''
          cp $gmp depends/${fetchGmp.name}
          bash build_gmp.sh windows_x86_64
          test -f depends/gmp/package_windows_x86_64/lib/libgmp.a # build_gmp.sh exits 0 even if GMP fails to build.
          make windows_x86_64_static
        '';

        installPhase = ''
          cp -r package_windows_x86_64 $out
          cp depends/gmp/package_windows_x86_64/include/gmp.h $out/include/
        '';
      };
    in
    {
      packages = lib.recursiveUpdate (lib.mapAttrs (
        system: host:
        let
          packages = lib.genAttrs [ host "windows-x86_64" ] (fetchRelease system);
        in
        packages // { default = packages.${host}; }
      ) hostPackages) { x86_64-linux.windows-x86_64-source = windowsSource; };
    };
}

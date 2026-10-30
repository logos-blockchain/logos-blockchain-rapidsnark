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
    in
    {
      packages.x86_64-linux.windows-x86_64 = windowsPkgs.stdenv.mkDerivation {
        pname = "rapidsnark-windows-x86_64";
        version = self.shortRev or "dirty";
        src = self;

        # Prefetch gmp so we can build GMP without network (during build)
        gmp = fetchGmp;

        depsBuildBuild = [ buildPkgs.stdenv.cc ];
        nativeBuildInputs = [ buildPkgs.cmake buildPkgs.gnumake buildPkgs.m4 ];
        buildInputs = [ windowsPkgs.windows.mcfgthreads windowsPkgs.windows.pthreads ];

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
        '';
      };
    };
}

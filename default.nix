{ pkgs ? import <nixpkgs> {}
, fetchurl ? pkgs.fetchurl
, autoPatchelfHook ? pkgs.autoPatchelfHook
}:
with pkgs; stdenv.mkDerivation rec {
  name = "hp-uld-driver";
  src = fetchurl {
    url = "https://ftp.hp.com/pub/softlib/software13/printers/MFP170/uld-hp_V1.00.39.12_00.15.tar.gz";
    sha256 = "07f9gf9fk7b6fh2ckiv63phx2xqln2c2m75v6ik41rr5c5xrpfyf";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    cups.lib
    stdenv.cc.cc.lib
    libusb1
    libxml2
  ];

  unpackPhase = ''
  tar -xf $src
  '';


  installPhase = ''
    distdir="uld/x86_64"
    distdir_noarch="uld/noarch"
    cupsbin="$out/lib/cups";

    install -v -m 755 -d $out/lib
    install -v -m 644 $distdir/libscmssc.so $out/lib/libscmssc.so

    install -v -m755 -d $out/bin

    # Install filters
    install -v -m755 -d "$cupsbin/filter"
    for f in pstosecps rastertospl; do
      install -v -m755 "$distdir/$f" "$out/bin/$f"
      ln -s "$out/bin/$f" "$cupsbin/filter/$f"
    done

    # Install backends
    install -v -m755 -d $out/lib/cups/backend
    install -v -m755 "$distdir/smfpnetdiscovery" "$out/bin/smfpnetdiscovery"
    ln -s "$out/bin/smfpnetdiscovery" "$cupsbin/backend/smfpnetdiscovery"

    # Install ppd
    ppddir=$out/share/cups/model/HP

    install -v -m755 -d $ppddir
    cp -r "$distdir_noarch/share/ppd" "$ppddir"
  '';
}

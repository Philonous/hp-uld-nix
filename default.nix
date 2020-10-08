{ pkgs ? import <nixpkgs> {}
, fetchurl ? pkgs.fetchurl
}:
with pkgs; stdenv.mkDerivation rec {
  name = "hp-uld-driver";
  src = fetchurl {
    url = "https://ftp.hp.com/pub/softlib/software13/printers/MFP170/uld-hp_V1.00.39.12_00.15.tar.gz";
    sha256 = "07f9gf9fk7b6fh2ckiv63phx2xqln2c2m75v6ik41rr5c5xrpfyf";
  };

  buildInputs = [
    cups.lib
    stdenv.cc.cc.lib
    libusb1
  ];

  unpackPhase = ''
  tar -xf $src
  '';

  installPhase = ''
    distdir="uld/x86_64"
    distdir_noarch="uld/noarch"
    cupsbin="$out/lib/cups";

    install -v -m755 -d $out/lib
    install -v -m755 $distdir/libscmssc.so $out/lib/libscmssc.so

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

  postFixup = ''
    # Set interpreters
    for f in pstosecps rastertospl smfpnetdiscovery; do
        patchelf --set-interpreter \
           ${stdenv.glibc}/lib/ld-linux-x86-64.so.2  \
           "$out/bin/$f"
    done

    # rastertospl needs libscmssc.so and libcups
    patchelf --set-rpath "$out/lib":"${cups.lib}/lib" "$out/bin/rastertospl"
    patchelf --add-needed libscmssc.so "$out/bin/rastertospl"
    patchelf --set-rpath "${stdenv.cc.cc.lib}/lib" "$out/lib/libscmssc.so"

    # pstosecps needs libcups
    patchelf --set-rpath "${cups.lib}/lib" "$out/bin/pstosecps"

    # smfpnetdiscovery
    patchelf --set-rpath "${stdenv.cc.cc.lib}/lib" "$out/bin/smfpnetdiscovery"

  '';
}

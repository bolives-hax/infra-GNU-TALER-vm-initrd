{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    busybox-snapshot-src  = {
      url = "https://www.busybox.net/downloads/busybox-snapshot.tar.bz2";
      flake = false;
      type = "file";
    };
  };

  outputs = {self,nixpkgs,flake-utils,busybox-snapshot-src,...}:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = {
          busybox = pkgs.stdenv.mkDerivation {
            name = "busybox";

            strictDeps = true;
            depsBuildBuild = with pkgs; [ buildPackages.stdenv.cc stdenv.cc.libc stdenv.cc.libc.static ];

            unpackPhase = ''
              mkdir -p source
              tar -xvf ${busybox-snapshot-src} --strip-components=1 -C source
              cp ${./busybox.config} source/.config
              cd source
            '';
            #buildPhase = "cd source ; make -j $(nproc)";
            installPhase = "cp busybox $out";
            src = busybox-snapshot-src;
          };
          taler-initrd = pkgs.stdenv.mkDerivation {
            name = "taler-initrd";
            depsBuildBuild = with pkgs; [
              cpio
              util-linux # column command
            ];
            phases = [ "unpackPhase" "buildPhase" "installPhase"];
            unpackPhase = ''
              mkdir source
              cp ${self.packages.${system}.busybox} source/busybox
              cp -a ${./initrd_include}/. source/
            '';

            # note if busybox is not at /bin/busybox it will fail
            # the for loop populates /bin as everything in /bin/
            # calls busybox busybox uses argv[0] to determine what program is run
            # thus ln -s /bin/busybox /bin/pwd
            # and then /bin/pwd would call busyboxes pwd applet
            buildPhase = ''
              chmod u+w source
              cd source
              mkdir -p {bin,sbin,dev,etc,proc}
              mv busybox bin/
              for applet in $(./bin/busybox --list); do ln -s busybox bin/$applet; done
	      find . | cpio -o -H newc | gzip > initrd.cpio.gz
            '';
            installPhase = ''
              echo initrd contains the following files:
	      gunzip -c initrd.cpio.gz | cpio -t --quiet | column
              mv initrd.cpio.gz $out
            '';
          };
        };
      });
}

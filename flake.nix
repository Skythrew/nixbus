{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, utils, rust-overlay }:
    utils.lib.eachDefaultSystem (system:
      let
        buildTarget = "x86_64-unknown-linux-gnu";
        packageName = "nixbus";
        
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
  
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ buildTarget ];
        };
  
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

        nixbus = rustPlatform.buildRustPackage {
          name = packageName;
          src = ./.;
          
          cargoLock.lockFile = ./Cargo.lock;
            
          buildPhase = ''
            cargo build --release -p ${packageName} --target=${buildTarget}
          '';
  
          installPhase = ''
            mkdir -p $out/bin/
            cp target/${buildTarget}/release/nixbus $out/bin/

            mkdir -p $out/share/dbus-1/system.d/
            cp $src/dbus/io.github.skythrew.nixbus.conf $out/share/dbus-1/system.d/io.github.skythrew.nixbus.conf

            mkdir -p $out/lib/systemd/system
            cp $src/systemd/nixbus.service $out/lib/systemd/system/nixbus.service

            mkdir -p $out/share/polkit-1/actions
            cp $src/polkit/io.github.skythrew.nixbus.policy $out/share/polkit-1/actions/io.github.skythrew.nixbus.policy
          '';
        };
      in {
        packages.default = nixbus;

        nixosModules.default = { ... } : {
          environment.systemPackages = [ nixbus ];

          systemd.services.nixbus = {
            description = "Nixbus D-Bus daemon";
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "notify";
            path = [ nixbus ];
            script = "${nixbus}/bin/nixbus";
          };

          services.dbus.packages = [ nixbus ];
        };
    }
  );
}

# Nixbus

## Installation

As usual with Rust, a simple `cargo build` will be able to build the whole project.

After compiling, please make sure to include the dbus service as well as the polkit policy to the system.

The dbus service usually goes to the `/etc/dbus-1/services` or `/usr/share/dbus-1/services` directory, while the polkit policy usually goes to the `/etc/polkit-1/actions` or `/usr/share/polkit-1/actions` directory.

For now, these are the only instructions the project needs to be built and ran.

**If you are building this on NixOS** (I'm almost sure you are), things are quite easy, just clone the repo and write a simple:

```
nix build
```

And there you are, with `nixbus` built! 
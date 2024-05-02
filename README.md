# infra-GNU-TALER-vm-initrd
nix expression to build a busybox based initrd chainloader with erofs+nfs(vsock)+virto-...+overlayfs initrd

## usage

for busybox alone

```bash
nix build .#busybox
```

for the initrd

```bash
nix build .#taler-initrd
```

make sure to pass ```init=/init``` to the kernels cmdline as the init script may pay attention to that

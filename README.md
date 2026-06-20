# apk-backup

`apk-backup` - a small POSIX shell script for OpenWrt that backs up
`/etc/apk/world` (the explicitly installed top-level packages, as tracked
by apk itself) and can restore them after a reflash or reset. Because only
the explicitly requested packages are saved - not packages that were merely
pulled in as dependencies - `apk add` resolves the correct dependency set
fresh against the repos of the release you're restoring onto, instead of
force-installing packages that a newer release no longer needs.

The script is meant to live as a hidden file under `/etc/config/` so that:

- it survives `sysupgrade` backups (which include the whole `/etc/config/` tree)
- `uci` does not try to parse it as a config file (hidden filename)

Pre-built, signed releases: **https://github.com/dr-ni/apk-backup/releases**

## Installation

### Recommended: install the pre-built apk package

Signed releases (Trezor-GPG-signed `.apk` + detached `.asc` signature)
are published at:

**https://github.com/dr-ni/apk-backup/releases**

**Quickest: download directly on the router** (if it has internet access):

| Step | Command |
|---|---|
| Download the release asset | `wget https://github.com/dr-ni/apk-backup/releases/download/<TAG>/apk-backup-<VERSION>.apk` |
| Download the signature (optional) | `wget https://github.com/dr-ni/apk-backup/releases/download/<TAG>/apk-backup-<VERSION>.apk.asc` |
| Install | `apk add --allow-untrusted apk-backup-<VERSION>.apk` |

**Alternative: copy from your dev machine** (e.g. if the router has
no internet access, or you've already downloaded it for verification -
see [Verifying a release](#verifying-a-release)):

```sh
scp-openwrt apk-backup-<version>.apk root@OpenWrt:/tmp/
ssh-openwrt
apk add --allow-untrusted /tmp/apk-backup-<version>.apk
```

This installs the script to `/usr/sbin/apk-backup`, so it's available
on `$PATH` as `apk-backup` - no manual file placement, dot-prefix, or
chmod needed.

### Alternative: install the hidden script manually

```sh
scp apk-backup root@openwrt:/etc/config/.apk-backup
ssh root@openwrt chmod +x /etc/config/.apk-backup
```

### Building the apk package yourself

`pkgbuild/build.sh` builds an installable `.apk` package using `apk mkpkg`.

**Note:** the `apk` binary shipped on OpenWrt itself does *not* include
`mkpkg` (package creation is stripped from that build) - so the package
must be built on a separate Linux machine with a full apk-tools 3.x,
then copied to the router for installation. No OpenWrt SDK/toolchain
is needed either way, since this package is just a shell script.

**1. Build full apk-tools 3.x on your dev machine** (e.g. `uwepc`/`unuc`):

```sh
sudo apt install meson ninja-build gcc pkg-config libssl-dev zlib1g-dev liblzma-dev libzstd-dev
git clone https://gitlab.alpinelinux.org/alpine/apk-tools.git
cd apk-tools
meson setup build
ninja -C build
sudo ninja -C build install
sudo ldconfig
apk --version   # should print something like "apk-tools 3.0.6-..."
```

**2. Build the package:**

```sh
cd pkgbuild
./build.sh
```

This produces `apk-backup-1.0-r1.apk` in the `pkgbuild/` directory.

**3. Copy the built package to the router and install it:**

```sh
scp-openwrt apk-backup-1.0-r1.apk root@OpenWrt:/tmp/
ssh-openwrt
apk add --allow-untrusted /tmp/apk-backup-1.0-r1.apk
```

### Releasing a signed package (GitHub release, Trezor-signed)

`pkgbuild/release.sh` builds the package and publishes it as a GitHub
release asset with a detached GPG signature, using the same
Trezor-backed GPG key as the onboard-osk/onboard releases.

```sh
cd pkgbuild
./release.sh v1.0-r1
```

This will:
1. run `build.sh`
2. `gpg --detach-sign --armor` the resulting `.apk` (Trezor confirmation required)
3. create a signed git tag (`git tag -s`, Trezor confirmation required)
4. create a GitHub release via `gh release create`, uploading both
   the `.apk` and its `.apk.asc` signature

### Verifying a release

```sh
gpg --verify apk-backup-<version>.apk.asc apk-backup-<version>.apk
```

This signs the release asset, not the apk-tools v3 package format
itself (apk-tools' own `--sign-key` mechanism needs a plain RSA key
file it can load directly, which isn't compatible with the Trezor's
SSH/GPG agent interface). So `apk add` on the router still needs
`--allow-untrusted` regardless of the GPG-signed release.

## Usage

### Which install method to use

|                          | apk package                          | hidden script                          |
|--------------------------|---------------------------------------|------------------------------------------|
| Setup effort             | upload via LuCi or scp `apk add`                        | manual `scp` + `chmod` after every reinstall |
| Survives `sysupgrade`?   | yes - but only the backup list | yes - hidden file under `/etc/config/` |
| On `$PATH`?              | yes - `apk-backup` from anywhere     | no - needs the full `/etc/config/.apk-backup` path |
| Dependency tracking      | shows up in `apk info`/`apk list -I`, gets removed cleanly via `apk del` | invisible to apk, manual cleanup only |
| Build/update step needed | yes - new `.apk` per version (or just download the release) | no - edit the file directly |

The apk package is the better default for most cases: it's on
`$PATH`, shows up as a real package, and (if installed from a signed
release) gives you something to verify before trusting it. The hidden
script is useful if you want to read or tweak the script directly on
the router without rebuilding a package, or don't want to deal with
`apk add`/`--allow-untrusted` at all.

If installed as an apk package:

```sh
apk-backup -b | --backup | backup     # write currently installed packages to .apk-backup.out
apk-backup -r | --restore | restore   # install all packages listed in .apk-backup.out
apk-backup -h | --help | help         # show help text
```

If installed manually as the hidden script (run with the full path,
or `cd /etc/config` first):

```sh
/etc/config/.apk-backup -b | --backup | backup
/etc/config/.apk-backup -r | --restore | restore
/etc/config/.apk-backup -h | --help | help
```

Output file: `/etc/config/.apk-backup.out` (a copy of `/etc/apk/world` at backup time)

### Example: scheduled backup via cron

Installed as an apk package:

```sh
echo '0 3 * * * apk-backup -b' >> /etc/crontabs/root
```

Hidden script:

```sh
echo '0 3 * * * /etc/config/.apk-backup -b' >> /etc/crontabs/root
```

### Restore after reflash

After a fresh OpenWrt install, copy `.apk-backup.out` back to
`/etc/config/` and run:

Installed as an apk package:

```sh
apk-backup -r
```

Hidden script:

```sh
/etc/config/.apk-backup -r
```

## License

GPLv3, see [LICENSE](LICENSE).

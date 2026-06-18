# apk-backup

A small POSIX shell script for OpenWrt that backs up the
list of currently installed `apk` packages and can restore them after a
reflash or import.

The script is meant to live as a hidden file under `/etc/config/` so that:

- it survives `sysupgrade` backups (which include the whole `/etc/config/` tree)
- `uci` does not try to parse it as a config file (hidden filename)

## Installation

```sh
scp apk-backup root@openwrt:/etc/config/.apk-backup
ssh root@openwrt chmod +x /etc/config/.apk-backup
```

## Usage

```sh
/etc/config/.apk-backup -b | --backup | backup     # write currently installed packages to .apk-backup.out
/etc/config/.apk-backup -r | --restore | restore   # install all packages listed in .apk-backup.out
/etc/config/.apk-backup -h | --help | help         # show help text
```

Output file: `/etc/config/.apk-backup.out`

### Example: scheduled backup via cron

```sh
echo '0 3 * * * /etc/config/.apk-backup -b' >> /etc/crontabs/root
```
If you make a backup of your OpenWrt settings it will also include all manually added packages.

### Restore

After a fresh OpenWrt install, import your backup via LuCi or copy manually `.apk-backup.out` back to
`/etc/config/` and run:

```sh
/etc/config/.apk-backup -r
```

## License

GPLv3, see [LICENSE](LICENSE).

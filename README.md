# apk-backup

`apk-backup` - a small POSIX shell script for OpenWrt that backs up the
list of currently installed `apk` packages and can restore them after a
reflash or reset.

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
.apk-backup backup    # write currently installed packages to .apk-backup.out
.apk-backup restore   # install all packages listed in .apk-backup.out
.apk-backup help      # show help text
```

Output file: `/etc/config/.apk-backup.out`

### Example: scheduled backup via cron

```sh
echo '0 3 * * * /etc/config/.apk-backup backup' >> /etc/crontabs/root
```

### Restore after reflash

After a fresh OpenWrt install, copy `.apk-backup.out` back to
`/etc/config/` and run:

```sh
.apk-backup restore
```

## License

GPLv3, see [LICENSE](LICENSE).

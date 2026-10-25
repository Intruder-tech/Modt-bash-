# Matrix Host MOTD

A custom SSH login banner (MOTD) for Linux servers. It shows an ASCII fox next to live system stats.

## Install

Run as root:

```bash
curl -fsSL https://matrixhost.in/motd.sh | sudo bash
```

Or install straight from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/Intruder-tech/Modt-bash-/main/install.sh | sudo bash
```

Requires `python3`.

## What it shows

OS, kernel, architecture, CPU model, cores and usage, RAM, swap, disk, IP address, network interfaces, uptime, load average, process count, logged-in users and server time.

## What the installer changes

- Installs the renderer at `/usr/local/bin/matrix-motd`.
- Adds `/etc/profile.d/00-matrix-motd.sh`. It runs the banner once per SSH login.
- Removes the default executable bit from every script in `/etc/update-motd.d/`. This turns off the stock Ubuntu/Debian dynamic MOTD.
- Writes `/etc/ssh/sshd_config.d/99-matrix-motd.conf` with `PrintMotd no`.
- Removes older Matrix Host MOTD scripts from `/etc/profile.d/`.

Run the banner by hand at any time:

```bash
matrix-motd
```

## Uninstall

```bash
sudo rm -f /usr/local/bin/matrix-motd \
  /etc/profile.d/00-matrix-motd.sh \
  /etc/ssh/sshd_config.d/99-matrix-motd.conf
sudo chmod a+x /etc/update-motd.d/*
```

## Credits

Made by **[Matrix Host](https://matrixhost.in)**, premium hosting infrastructure.
Support: support@matrixhost.in

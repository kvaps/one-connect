# OpenNebula VM Connector

Simple and secure bash-script that provides your users access to own OpenNebula VMs via SPICE. VNC is also supported.

No Sunstone needed, connecting carried directly from user's desktop.

Script automatically suspend VM after disconnect and resume VM when user connect.

It allows you to organize simplest VDI structure.

## Usage

```bash
Usage:    vm-connect.sh --host HOST [--username USERNAME]

Arguments:
    -H, --host                  OpenNebula hostname or IP
    -u, --user                  Username for SSH-connection
    -l, --log-file              Path to log file
    -d, --debug                 Enable debug output
    -h, --help                  This message
```

## Installation

* Install [dependings](#dependings)
* Configure passwordless SSH authentication to your OpenNebula host.
* Authorise user on OpenNebula host via `oneuser login` command.
* Also you may to configure [SSH Auth](http://docs.opennebula.org/4.12/administration/authentication/ssh_auth.html)

## Dependings

### Linux

Just install `virt-viewer` and `zenity` packages.

If you intend to use Cyrillic and other character encodings in virtual machines names, please install `recode`, it will be convert html characters in virtual machines names.

### Windows

Install:

* **Virt-viewer**
  [[windows binary](https://virt-manager.org/download/)]

Also, don't forget to add virt-viewer bin folder to your windows PATH [[howto](http://superuser.com/a/317638)]

#### Git Bash

The simple way. Just install:

* **Git Bash** (with adding unix tools to PATH)
  [[windows binary](https://git-for-windows.github.io/)]

* **Zenity**
  [[windows binary](https://github.com/kvaps/zenity-windows)]

*My zenity build for windows already contains `recode` package.*

Create shortcut for start vm-connect script:

    mintty.exe -w hide -e bash -c "C:\Soft\one-connect\vm-connect.sh" -H hostname -u user

Or for enable debug output:

    mintty.exe -e bash -c "C:\Soft\one-connect\vm-connect.sh" -d -H hostname -u user

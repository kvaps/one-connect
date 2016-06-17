# OpenNebula VM Connector

Simple and secure bash-script that provides your users access to own OpenNebula VMs via SPICE. VNC is also supported.

No Sunstone needed, connecting carried directly from user's desktop.

Script automatically suspend VM after disconnect and resume VM when user connect.

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

### Windows

* **Virt-viewer**
  [[windows binary](https://virt-manager.org/download/)]

Also, don't forget to add virt-viewer bin folder to your windows PATH [[howto](http://superuser.com/a/317638)]

Next, you have a two way:

#### Git Bash

The simple way. Just install:

* **Git Bash**
  [[windows binary](https://git-for-windows.github.io/)]

* **Zenity**
  [[windows binary](http://www.placella.com/software/zenity/#downloads)]

You can run script using launcher.exe from [release v1.0](https://github.com/kvaps/one-connect/releases/download/v1.0/one-connect.zip)

#### Cygwin 

This way is more complex, but provides a more recent versions of the software that allows you to avoid some bugs. Install:

* **Cygwin**
  [[windows binary](http://www.cygwin.com/install.html)]


During installation, select the following additional packages:
  - xorg-server
  - xinit
  - openssh
  - zenity
  - dbus

Use this command for xorg-server autostart:

    C:\cygwin\bin\mintty.exe -w hide -e /bin/bash -lc 'startxwin'

Create shortcut for start vm-connect script:

    C:\cygwin\bin\mintty.exe -w hide -e /bin/bash -lc '$(cygpath "C:\Soft\one-connect\vm-connect.sh") -H hostname -u user'

Or for enable debug output:

    C:\cygwin\bin\mintty.exe -e /bin/bash -lc '$(cygpath "C:\Soft\one-connect\vm-connect.sh") -d -H hostname -u user'

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

* **Virt-viewer**
  [[windows binary](https://virt-manager.org/download/)]

* **Zenity**
  [[windows binary](http://www.placella.com/software/zenity/#downloads)]

Windows only:
* **MinGW** (msys-base package)
  [[windows binary](https://sourceforge.net/projects/mingw/)]

*Also, don't forget to add virt-viewer bin folder to your windows PATH [[howto](http://superuser.com/a/317638)]*


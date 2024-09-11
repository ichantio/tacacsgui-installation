# TACACS GUI Installation
TACACSGUI - Updated for Newer OS - Installer

# DONATION
This work made me consume copious amount of coffee. If you want to help me then get me some more.  
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/vlab)

# DISCLAIMER
- I am **NOT** a web developer.
- I fumble through the code and fix what I can so it works on Ubuntu 22.04 and 24.04 with newer software packages.
- SUPPORT: Pretty much none, zip, nada, etc. No support is available private or otherwise.
- If you create an github issue, I **MAY** look at this and attempt to fix it whenever I have free time.

# Tested on

OS                                | PHP       | Python        | MySQL        | tac_plus
---                               | ---       | ---           | ---          | ---
Ubuntu Server 22.04 LTS STANDARD  | PHP8.3    | Python3.10.12 | MySQL 8.0.39 | tac_plus latest dl 2024-09-11
Ubuntu Server 24.04 LTS STANDARD  | PHP8.3.6  | Python3.12.3  | MySQL 8.0.39 | tac_plus latest dl 2024-09-11

# Requirement:
- Ubuntu 22.04 or 24.04 LTS Standard Installation
- `sudo` or `root` access
- Packages: `git`
- Internet access to public repos

# How-to
## Install TACACSGUI
- Download the repo, set any required params in  
[conf/install_params.conf](conf/install_params.conf)
```bash
git clone https://github.com/ichantio/tacacsgui-installation.git
cd tacacsgui-installation
chmod +x installer.sh

# Set web server required params if not, it will uses the default
# If you have a real DNS name, set it here
WEBSERVER_NAME=tacacsgui.lan
# Set to 1 will generate a self signed certificate
# Set to 0 will generate a key and csr for getting a certificate from a CA
WEBSERVER_SELFSIGNED_CERT=1
```

- Run `installer.sh`
```bash
sudo ./installer.sh
```
## What does the repo contain?
- Installer script [installer.sh](installer.sh)
- Simple firewall setup script [setup-firewall.sh](setup-firewall.sh)
- [tac_plus.tgz](tac_plug.tgz) compressed package downloaded 2024-09-11  
:exclamation: There is `tac_plus-ng` but I haven't got time to test it out

## Configure firewall
- Host firewall support.
I build a quick script to set `ufw` and `firewalld`. By default, is `none`.
- The config file is in [conf/firewall_params.conf](conf/firewall_params.conf)  
:warning: **DO NOT FORGET YOUR OWN ACCESS**
```bash
# EXAMPLE PARAMETERS
192.168.0.0/24;22:tcp,80,tcp,443:tcp
192.168.1.0/24;49:tcp
192.168.2.0/24;80:any
```

- Run by specify your options using:
```bash
# Permission
chmod +x setup-firewall.sh
# UFW
sudo ./setup-firewall.sh --fw=ufw
# FIREWALLD
sudo ./setup-firewall.sh --fw=firewalld
# Specify your own parameters file
sudo ./setup-firewall.sh --fw=ufw --fire=new-rule.conf
```

# Code status
The installer was written from scratch for it to work with Ubuntu 22.04 and 24.04

# License
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Author
@me

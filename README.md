# TACACS GUI Installation
TACACSGUI - Updated for Newer OS - Installer

# DISCLAIMER
- I am NOT a web developer.
- I fumble through the code and fix what I can so it works on Ubuntu 22.04 with newer software packages.
- SUPPORT: None, zip, nada. No support is available private or otherwise.
- If you create an github issue, I **MAY** look at this and attempt to fix it whenever I have free time.

# Tested on
- Ubuntu Server 22.04 LTS Standard Installation
- PHP8.3
- Python3.10.12
- MySQL 8.0.39

# Requirement:
- Ubuntu 22.04 LTS Standard Installation
- `sudo` or `root` access
- Packages: `git`
- Internet access to public repos

# How-to
- Download the repo and run `installer.sh`  
Example method below
```bash
git clone https://github.com/ichantio/tacacsgui-installation.git
cd tacacsgui-installation
chmod +x installer.sh
sudo ./installer.sh
```

- Host firewall support.
The installer support `ufw` and `firewalld`. Default presume you run `ufw`. Specify `firewalld` using:
```bash
sudo ./installer.sh --with-firewalld
```
If you don't have host firewall. Run
```bash
sudo ./installer.sh --no-host-firewall
```

- If you change your mind later and want to add host firewall
```bash
sudo chmod +x set-firewall.sh
sudo ./set-firewall --ufw
sudo ./set-firewall --firewalld
```

# License
Apache 2.0

# Author
Me

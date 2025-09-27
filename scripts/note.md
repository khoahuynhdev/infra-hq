# Create new VM in the hq

1. Download the ISO (eg. Fedora Server)

```bash

curl -O https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-1.1.iso
```

2. Import the ISO to hq using cockpit

- Click on Create VM
- Choose Local install media (ISO image or CDROM)
- Use storage Limit 50G
- Use Memory 4GB
- Create and Run

# Kubernetes setup error

- Worker domain can collide with cluster domain -> update domain for node accordingly

# wireguard

make sure to stop the right interface

```bash
# Stop the WireGuard service
sudo systemctl stop wg-quick@<interface-name>

# For example, if your interface is wg0:
sudo systemctl stop wg-quick@wg0

# Disable it from starting at boot
sudo systemctl disable wg-quick@wg0

# Check status to confirm it's stopped
sudo systemctl status wg-quick@wg0
```

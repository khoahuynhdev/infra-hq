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

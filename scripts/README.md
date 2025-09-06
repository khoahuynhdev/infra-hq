## Usage

## add-vm.sh

### Basic usage

./add-vm.sh worker-1

### With custom size

./add-vm.sh --size 40G worker-2

### Dry-run mode

./add-vm.sh --dry-run --size 50G test-vm

### Help

./add-vm.sh --help

The script now implements all the functionality described in the original comments with robust error
handling and user-friendly output

## sshf

### basic usage

```bash
sshf -i ~/.ssh/work_key user@work-server.com

```

### Custom port with command execution

```bash
sshf -p 2222 user@server.com 'ls -la /home'

```

#!/usr/bin/env bash

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
FEDORA_IMAGE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/images/Fedora-Server-Guest-Generic-42-1.1.x86_64.qcow2"
LIBVIRT_IMAGES_DIR="/var/lib/libvirt/images"
DRY_RUN=false
VM_NAME=""
DISK_SIZE="20G"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_dry_run() {
    echo -e "${CYAN}[DRY-RUN]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] VM_NAME

Download and prepare a Fedora VM image for libvirt.

OPTIONS:
    -s, --size SIZE     Disk size for the VM (default: 20G)
    -d, --dry-run       Show what would be done without executing
    -h, --help          Show this help message

EXAMPLES:
    $0 worker-1
    $0 --size 40G worker-2
    $0 --dry-run --size 50G test-vm

EOF
}

# Execute command with dry-run support
execute() {
    local cmd="$1"
    if [ "$DRY_RUN" = true ]; then
        log_dry_run "Would execute: $cmd"
    else
        log_info "Executing: $cmd"
        eval "$cmd"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--size)
                DISK_SIZE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$VM_NAME" ]; then
                    VM_NAME="$1"
                else
                    log_error "Multiple VM names provided"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$VM_NAME" ]; then
        log_error "VM name is required"
        show_help
        exit 1
    fi
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ] && ! groups | grep -q libvirt; then
        log_error "This script requires root privileges or membership in the libvirt group"
        exit 1
    fi
    
    # Check required commands
    local required_commands=("wget" "qemu-img")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    # Check if libvirt images directory exists
    if [ ! -d "$LIBVIRT_IMAGES_DIR" ] && [ "$DRY_RUN" = false ]; then
        log_error "Libvirt images directory '$LIBVIRT_IMAGES_DIR' does not exist"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Download Fedora image
download_image() {
    local image_filename="${VM_NAME}-fedora-42-server.qcow2"
    local image_path="${LIBVIRT_IMAGES_DIR}/${image_filename}"
    
    log_info "Downloading Fedora Server 42 image..."
    log_info "Target: $image_path"
    
    if [ -f "$image_path" ] && [ "$DRY_RUN" = false ]; then
        log_warning "Image already exists at $image_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping download"
            return 0
        fi
    fi
    
    execute "wget '$FEDORA_IMAGE_URL' -O '$image_path'"
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Image downloaded successfully"
    fi
}

# Print image information
print_image_info() {
    local image_filename="${VM_NAME}-fedora-42-server.qcow2"
    local image_path="${LIBVIRT_IMAGES_DIR}/${image_filename}"
    
    log_info "Image information:"
    execute "qemu-img info '$image_path'"
}

# Resize image
resize_image() {
    local image_filename="${VM_NAME}-fedora-42-server.qcow2"
    local image_path="${LIBVIRT_IMAGES_DIR}/${image_filename}"
    
    log_info "Resizing image to $DISK_SIZE..."
    execute "qemu-img resize '$image_path' '$DISK_SIZE'"
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Image resized to $DISK_SIZE"
    fi
}

# Main function
main() {
    parse_args "$@"
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY-RUN MODE ENABLED - No actual changes will be made"
    fi
    
    log_info "Setting up VM: $VM_NAME"
    log_info "Disk size: $DISK_SIZE"
    
    validate_prerequisites
    download_image
    print_image_info
    resize_image
    print_image_info
    
    if [ "$DRY_RUN" = false ]; then
        log_success "VM image setup completed successfully!"
        log_info "Image location: ${LIBVIRT_IMAGES_DIR}/${VM_NAME}-fedora-42-server.qcow2"
    else
        log_info "Dry-run completed. Use without --dry-run to execute actual commands."
    fi
}

main "$@"

#!/bin/bash
#
# vm-to-bridge.sh - Convert Libvirt VMs from NAT to Bridge Networking
#
# This script reconfigures existing virtual machines to use bridge networking
# instead of NAT. After running this script, your VMs will appear as separate
# devices on your LAN with their own IP addresses from your router, rather than
# being hidden behind the host's IP address.
#
# Think of this as updating a person's mailing address from "Apartment 3 in the
# Main Building" to "123 Main Street, House 3" - they're moving from a shared
# address to their own dedicated address.
#
# Prerequisites:
#   - Bridge network must already be configured (use setup-bridge.sh first)
#   - You must have a libvirt bridge network defined (typically 'host-bridge')
#
# Usage: sudo ./vm-to-bridge.sh [vm-name]
#   If vm-name is not provided, the script will show a menu of available VMs
#

set -e # Exit immediately if any command fails

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
	echo ""
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}$1${NC}"
	echo -e "${BLUE}========================================${NC}"
	echo ""
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
	print_error "This script must be run as root (use sudo)"
	exit 1
fi

print_header "VM Network Conversion: NAT to Bridge"

# Step 1: Check if bridge network exists
print_header "Step 1: Checking Bridge Network Availability"

# Look for available bridge networks in libvirt
print_status "Scanning for available bridge networks..."
BRIDGE_NETWORKS=$(virsh net-list --all | grep -i bridge | awk '{print $1}' || true)

if [[ -z "$BRIDGE_NETWORKS" ]]; then
	print_error "No bridge networks found in libvirt!"
	echo ""
	echo "You need to set up a bridge network first."
	echo "Run the 'setup-bridge.sh' script to create one."
	exit 1
fi

# Display available bridge networks
echo "Available bridge networks:"
echo "--------------------------"
for net in $BRIDGE_NETWORKS; do
	# Check if network is active
	STATE=$(virsh net-info "$net" | grep -i "Active" | awk '{print $2}')
	BRIDGE=$(virsh net-info "$net" | grep -i "Bridge" | awk '{print $2}')

	if [[ "$STATE" == "yes" ]]; then
		echo -e "  ${GREEN}●${NC} $net (Bridge: $BRIDGE, Active)"
	else
		echo -e "  ${RED}○${NC} $net (Bridge: $BRIDGE, Inactive)"
	fi
done
echo ""

# Ask user which bridge network to use
if [[ $(echo "$BRIDGE_NETWORKS" | wc -w) -eq 1 ]]; then
	# Only one bridge network, use it automatically
	BRIDGE_NETWORK="$BRIDGE_NETWORKS"
	print_success "Using bridge network: $BRIDGE_NETWORK"
else
	# Multiple bridge networks, ask user to choose
	read -p "Enter the bridge network name to use (default: host-bridge): " BRIDGE_NETWORK
	BRIDGE_NETWORK=${BRIDGE_NETWORK:-host-bridge}
fi

# Verify the chosen network exists and get its bridge name
if ! virsh net-info "$BRIDGE_NETWORK" &>/dev/null; then
	print_error "Bridge network '$BRIDGE_NETWORK' not found!"
	exit 1
fi

BRIDGE_NAME=$(virsh net-info "$BRIDGE_NETWORK" | grep -i "Bridge" | awk '{print $2}')

# Check if the network is active
BRIDGE_STATE=$(virsh net-info "$BRIDGE_NETWORK" | grep -i "Active" | awk '{print $2}')
if [[ "$BRIDGE_STATE" != "yes" ]]; then
	print_warning "Bridge network '$BRIDGE_NETWORK' is not active."
	read -p "Would you like to start it now? (Y/n): " start_net
	if [[ ! "$start_net" =~ ^[Nn]$ ]]; then
		virsh net-start "$BRIDGE_NETWORK"
		print_success "Bridge network started"
	else
		print_error "Cannot proceed with inactive bridge network"
		exit 1
	fi
fi

print_success "Using bridge: $BRIDGE_NAME (network: $BRIDGE_NETWORK)"

# Step 2: Select VM to convert
print_header "Step 2: Selecting Virtual Machine"

# Check if VM name was provided as argument
if [[ -n "$1" ]]; then
	VM_NAME="$1"
	print_status "Using VM from command line: $VM_NAME"
else
	# List all VMs (both running and stopped)
	print_status "Available virtual machines:"
	echo ""

	# Get list of all VMs with their state
	ALL_VMS=$(virsh list --all | tail -n +3 | grep -v "^$" | awk '{print $2,$3}')

	if [[ -z "$ALL_VMS" ]]; then
		print_error "No virtual machines found!"
		exit 1
	fi

	# Display VMs with their current state
	echo "$ALL_VMS" | while read vm state; do
		if [[ "$state" == "running" ]]; then
			echo -e "  ${GREEN}●${NC} $vm (running)"
		else
			echo -e "  ${RED}○${NC} $vm (shut off)"
		fi
	done
	echo ""

	read -p "Enter the VM name to convert: " VM_NAME
fi

# Verify VM exists
if ! virsh dominfo "$VM_NAME" &>/dev/null; then
	print_error "VM '$VM_NAME' not found!"
	exit 1
fi

# Check VM state
VM_STATE=$(virsh domstate "$VM_NAME")
print_status "VM '$VM_NAME' is currently: $VM_STATE"

# Step 3: Analyze current network configuration
print_header "Step 3: Analyzing Current Network Configuration"

print_status "Checking current network configuration for $VM_NAME..."

# Get the VM's current network configuration
NETWORK_CONFIG=$(virsh dumpxml "$VM_NAME" | grep -A 10 "interface type=")

# Extract current network type and source
CURRENT_TYPE=$(echo "$NETWORK_CONFIG" | grep "interface type=" | sed -n "s/.*type='\([^']*\)'.*/\1/p")
CURRENT_SOURCE=$(echo "$NETWORK_CONFIG" | grep "source network=" | sed -n "s/.*network='\([^']*\)'.*/\1/p")

if [[ -z "$CURRENT_SOURCE" ]]; then
	CURRENT_SOURCE=$(echo "$NETWORK_CONFIG" | grep "source bridge=" | sed -n "s/.*bridge='\([^']*\)'.*/\1/p")
fi

echo "Current configuration:"
echo "  Interface type: $CURRENT_TYPE"
echo "  Network source: ${CURRENT_SOURCE:-Direct bridge}"

# Get current IP if VM is running
if [[ "$VM_STATE" == "running" ]]; then
	CURRENT_IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1 || true)
	if [[ -n "$CURRENT_IP" ]]; then
		echo "  Current IP: $CURRENT_IP"
	fi
fi

# Check if already using the target bridge network
if [[ "$CURRENT_TYPE" == "network" ]] && [[ "$CURRENT_SOURCE" == "$BRIDGE_NETWORK" ]]; then
	print_warning "VM is already configured to use bridge network '$BRIDGE_NETWORK'"
	read -p "Do you want to reconfigure it anyway? (y/N): " reconfig
	if [[ ! "$reconfig" =~ ^[Yy]$ ]]; then
		print_status "No changes made."
		exit 0
	fi
fi

# Warn if VM is currently running
if [[ "$VM_STATE" == "running" ]]; then
	print_warning "VM is currently running. Network changes require a restart."
	echo "The VM will need to be shut down and restarted for changes to take effect."
	echo ""
fi

# Step 4: Backup current configuration
print_header "Step 4: Backing Up Current Configuration"

BACKUP_DIR="/var/lib/libvirt/backup"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/${VM_NAME}_$(date +%Y%m%d_%H%M%S).xml"
virsh dumpxml "$VM_NAME" >"$BACKUP_FILE"

print_success "Configuration backed up to: $BACKUP_FILE"
print_status "If something goes wrong, you can restore with:"
print_status "  sudo virsh define $BACKUP_FILE"

# Step 5: Update network configuration
print_header "Step 5: Updating Network Configuration"

print_warning "This will modify the VM's configuration to use bridge networking."
echo ""
read -p "Proceed with network configuration update? (y/N): " proceed_confirm

if [[ ! "$proceed_confirm" =~ ^[Yy]$ ]]; then
	print_status "Aborted by user. No changes made."
	exit 0
fi

print_status "Updating network configuration..."

# Use virsh edit programmatically via virt-xml (if available)
# Otherwise, we'll use sed to modify the XML directly
if command -v virt-xml &>/dev/null; then
	# virt-xml is a safer way to modify VM configs
	# Remove the old network interface and add the new one
	virt-xml "$VM_NAME" --edit --network network="$BRIDGE_NETWORK"
	print_success "Network configuration updated using virt-xml"
else
	# Fallback: manually edit the XML
	# This is more error-prone but works without additional tools

	# Create a temporary XML file
	TEMP_XML="/tmp/${VM_NAME}_temp.xml"
	virsh dumpxml "$VM_NAME" >"$TEMP_XML"

	# Replace the network source in the interface definition
	# This sed command finds the <source network='...'> tag and replaces it
	sed -i "s|<source network='[^']*'/>|<source network='$BRIDGE_NETWORK'/>|g" "$TEMP_XML"

	# If the interface was a direct bridge, change it to use the libvirt network
	sed -i "s|<source bridge='[^']*'/>|<source network='$BRIDGE_NETWORK'/>|g" "$TEMP_XML"

	# Also ensure interface type is 'network' not 'bridge'
	sed -i "s|<interface type='bridge'>|<interface type='network'>|g" "$TEMP_XML"

	# Undefine and redefine the VM with the new configuration
	virsh undefine "$VM_NAME"
	virsh define "$TEMP_XML"

	# Clean up temp file
	rm "$TEMP_XML"

	print_success "Network configuration updated"
fi

# Step 6: Restart VM if needed
print_header "Step 6: Applying Changes"

if [[ "$VM_STATE" == "running" ]]; then
	print_warning "VM must be restarted for changes to take effect."
	read -p "Restart VM now? (Y/n): " restart_confirm

	if [[ ! "$restart_confirm" =~ ^[Nn]$ ]]; then
		print_status "Shutting down VM gracefully..."
		virsh shutdown "$VM_NAME"

		# Wait for shutdown (max 30 seconds)
		print_status "Waiting for VM to shut down..."
		for i in {1..30}; do
			if [[ $(virsh domstate "$VM_NAME") == "shut off" ]]; then
				break
			fi
			sleep 1
		done

		# If still not shut down, force it
		if [[ $(virsh domstate "$VM_NAME") != "shut off" ]]; then
			print_warning "Graceful shutdown timed out, forcing shutdown..."
			virsh destroy "$VM_NAME"
		fi

		print_status "Starting VM..."
		virsh start "$VM_NAME"

		# Wait a moment for the VM to boot and get an IP
		print_status "Waiting for VM to acquire network configuration..."
		sleep 10

		print_success "VM restarted"
	else
		print_warning "VM was not restarted. Changes will take effect on next boot."
	fi
fi

# Step 7: Verify new configuration
print_header "Step 7: Verification"

# Show the new network configuration
print_status "New network configuration:"
NEW_NETWORK_CONFIG=$(virsh domiflist "$VM_NAME")
echo "$NEW_NETWORK_CONFIG"
echo ""

# If VM is running, try to get its new IP address
if [[ $(virsh domstate "$VM_NAME") == "running" ]]; then
	print_status "Attempting to detect VM's new IP address..."

	# Give it a few more seconds to fully boot and get DHCP
	sleep 5

	NEW_IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1 || true)

	if [[ -n "$NEW_IP" ]]; then
		print_success "VM's new IP address: $NEW_IP"
		print_status "This IP was assigned by your router's DHCP server"
		print_status "The VM should be accessible from anywhere on your LAN at this address"
	else
		print_warning "Could not automatically detect IP address yet"
		print_status "The VM may still be acquiring its DHCP lease"
		print_status "Check inside the VM or try: virsh domifaddr $VM_NAME"
	fi

	# Show the vnet interface info on the host
	VNET_IFACE=$(ip link show | grep "master $BRIDGE_NAME" | grep vnet | cut -d: -f2 | tr -d ' ')
	if [[ -n "$VNET_IFACE" ]]; then
		print_status "VM is connected via interface: $VNET_IFACE"
		print_status "This interface is attached to bridge: $BRIDGE_NAME"
	fi
else
	print_status "VM is not running. Start it to see its new network configuration."
	print_status "Run: sudo virsh start $VM_NAME"
fi

# Final summary
print_header "Conversion Complete!"

echo "VM '$VM_NAME' has been successfully converted to bridge networking!"
echo ""
echo "Summary:"
echo "  VM Name: $VM_NAME"
echo "  Bridge Network: $BRIDGE_NETWORK"
echo "  Bridge Interface: $BRIDGE_NAME"
echo "  Backup Location: $BACKUP_FILE"
if [[ -n "$NEW_IP" ]]; then
	echo "  New IP Address: $NEW_IP"
fi
echo ""
echo "What changed:"
echo "  - VM now connects to bridge '$BRIDGE_NAME' instead of NAT network"
echo "  - VM will receive IP addresses from your router's DHCP (not libvirt's DHCP)"
echo "  - VM is now directly accessible from any device on your LAN"
echo "  - No more NAT translation or port forwarding needed"
echo ""
print_success "All done! Your VM is now using bridge networking."

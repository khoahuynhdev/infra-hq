#!/bin/bash
#
# setup-bridge.sh - Configure Linux Bridge for KVM/Libvirt on Fedora
#
# This script sets up a network bridge that allows virtual machines to connect
# directly to your LAN, appearing as individual devices rather than being hidden
# behind NAT. Think of this as converting from an apartment building (where all
# VMs share one address) to individual houses on the same street (where each VM
# gets its own address from your router).
#
# IMPORTANT: This script will temporarily interrupt your network connection as it
# reconfigures your network interface. If you're connected via SSH, you will be
# disconnected. Run this from the physical console if possible.
#
# Usage: sudo ./setup-bridge.sh
#

set -e # Exit immediately if any command fails

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header "Bridge Network Setup for Fedora"

print_status "This script will configure your system to use bridge networking."
print_status "This allows VMs to appear as separate devices on your LAN."
echo ""

# Step 1: Identify the active network interface
print_header "Step 1: Identifying Active Network Interface"

print_status "Looking for active network interfaces..."

# Get list of network interfaces that are UP (excluding loopback and virtual interfaces)
# We filter out lo (loopback), virbr* (existing libvirt bridges), and vnet* (VM interfaces)
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$\|^virbr\|^vnet\|^br')

# Display available interfaces
echo ""
echo "Available network interfaces:"
echo "-----------------------------"
for iface in $INTERFACES; do
	# Get the current state and IP address if any
	state=$(ip link show "$iface" | grep -o 'state [A-Z]*' | awk '{print $2}')
	ipaddr=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

	if [[ -n "$ipaddr" ]]; then
		echo "  $iface (State: $state, IP: $ipaddr)"
	else
		echo "  $iface (State: $state, No IP)"
	fi
done
echo ""

# Ask user to confirm or specify the interface
read -p "Enter the interface name to bridge (e.g., enp0s31f6, eno1): " PHYSICAL_IFACE

# Validate that the interface exists
if ! ip link show "$PHYSICAL_IFACE" &>/dev/null; then
	print_error "Interface $PHYSICAL_IFACE does not exist!"
	exit 1
fi

# Check if interface is UP
if ! ip link show "$PHYSICAL_IFACE" | grep -q "state UP"; then
	print_warning "Interface $PHYSICAL_IFACE is not in UP state. It may not be connected."
	read -p "Do you want to continue anyway? (y/N): " confirm
	if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
		print_status "Aborted by user."
		exit 0
	fi
fi

print_success "Using interface: $PHYSICAL_IFACE"

# Step 2: Determine IP configuration method
print_header "Step 2: Configuring Bridge IP Method"

# Check if the interface currently uses DHCP
CURRENT_CONNECTION=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":$PHYSICAL_IFACE$" | cut -d: -f1)
CURRENT_METHOD=$(nmcli -t -f ipv4.method connection show "$CURRENT_CONNECTION" 2>/dev/null | cut -d: -f2)
CURRENT_IP=$(ip -4 addr show "$PHYSICAL_IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1)

echo "Current configuration:"
echo "  Connection: $CURRENT_CONNECTION"
echo "  IP Method: $CURRENT_METHOD"
echo "  IP Address: ${CURRENT_IP:-None}"
echo ""

print_status "How should the bridge obtain its IP address?"
echo "  1) DHCP (automatic, recommended for most home networks)"
echo "  2) Static IP (manual configuration, keeps current IP if available)"
echo ""
read -p "Choose option (1 or 2): " ip_choice

BRIDGE_METHOD=""
BRIDGE_IP=""
BRIDGE_GATEWAY=""
BRIDGE_DNS=""

case $ip_choice in
1)
	BRIDGE_METHOD="auto"
	print_success "Bridge will use DHCP"
	;;
2)
	BRIDGE_METHOD="manual"

	# If we have a current IP, offer to use it
	if [[ -n "$CURRENT_IP" ]]; then
		read -p "Use current IP address ($CURRENT_IP)? (Y/n): " use_current
		if [[ "$use_current" =~ ^[Nn]$ ]]; then
			read -p "Enter static IP address (with CIDR, e.g., 192.168.1.100/24): " BRIDGE_IP
		else
			BRIDGE_IP="$CURRENT_IP"
		fi
	else
		read -p "Enter static IP address (with CIDR, e.g., 192.168.1.100/24): " BRIDGE_IP
	fi

	read -p "Enter gateway IP (e.g., 192.168.1.1): " BRIDGE_GATEWAY
	read -p "Enter DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): " BRIDGE_DNS

	print_success "Bridge will use static IP: $BRIDGE_IP"
	;;
*)
	print_error "Invalid choice"
	exit 1
	;;
esac

# Step 3: Create the bridge
print_header "Step 3: Creating Bridge Interface"

BRIDGE_NAME="br0"

# Check if bridge already exists
if nmcli connection show "$BRIDGE_NAME" &>/dev/null; then
	print_warning "Bridge connection '$BRIDGE_NAME' already exists."
	read -p "Do you want to delete it and recreate? (y/N): " recreate
	if [[ "$recreate" =~ ^[Yy]$ ]]; then
		print_status "Deleting existing bridge..."
		nmcli connection delete "$BRIDGE_NAME" || true
		# Also delete the bridge slave if it exists
		nmcli connection delete "bridge-slave-$PHYSICAL_IFACE" 2>/dev/null || true
	else
		print_error "Cannot proceed with existing bridge. Please delete it manually or choose a different name."
		exit 1
	fi
fi

print_status "Creating bridge '$BRIDGE_NAME'..."

# Create the bridge connection
# The bridge acts like a virtual network switch that sits between your physical
# interface and the network stack. Your host and VMs will all connect to this switch.
nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME"

# Configure IP method for the bridge
if [[ "$BRIDGE_METHOD" == "auto" ]]; then
	# DHCP mode: the bridge will request an IP from your router
	nmcli connection modify "$BRIDGE_NAME" ipv4.method auto
	print_success "Bridge configured for DHCP"
else
	# Static IP mode: manually assign the IP address
	nmcli connection modify "$BRIDGE_NAME" \
		ipv4.method manual \
		ipv4.addresses "$BRIDGE_IP" \
		ipv4.gateway "$BRIDGE_GATEWAY" \
		ipv4.dns "$BRIDGE_DNS"
	print_success "Bridge configured with static IP"
fi

# Disable STP (Spanning Tree Protocol) startup delay
# STP prevents network loops but adds a delay. Since we're not creating loops
# with VM bridges, we can disable the delay for faster startup.
nmcli connection modify "$BRIDGE_NAME" bridge.stp no

# Enable the bridge to start automatically on boot
nmcli connection modify "$BRIDGE_NAME" connection.autoconnect yes

print_success "Bridge '$BRIDGE_NAME' created successfully"

# Step 4: Attach physical interface to bridge
print_header "Step 4: Attaching Physical Interface to Bridge"

print_status "Creating bridge slave connection for $PHYSICAL_IFACE..."

# The physical interface becomes a "slave" (or "port") of the bridge
# This means it no longer has its own IP address - it just acts as a cable
# connecting the bridge to your physical network
nmcli connection add type ethernet slave-type bridge \
	con-name "bridge-slave-$PHYSICAL_IFACE" \
	ifname "$PHYSICAL_IFACE" \
	master "$BRIDGE_NAME"

# Enable auto-connect for the slave as well
nmcli connection modify "bridge-slave-$PHYSICAL_IFACE" connection.autoconnect yes

print_success "Physical interface attached to bridge"

# Step 5: Activate the bridge
print_header "Step 5: Activating Bridge Network"

print_warning "This step will interrupt your network connection briefly!"
print_warning "If you're connected via SSH, you will be disconnected."
echo ""
read -p "Continue with bridge activation? (y/N): " activate_confirm

if [[ ! "$activate_confirm" =~ ^[Yy]$ ]]; then
	print_status "Bridge created but not activated. You can activate it manually with:"
	print_status "  sudo nmcli connection down '$CURRENT_CONNECTION'"
	print_status "  sudo nmcli connection up '$BRIDGE_NAME'"
	exit 0
fi

print_status "Bringing down current connection: $CURRENT_CONNECTION"
nmcli connection down "$CURRENT_CONNECTION" 2>/dev/null || true

print_status "Bringing up bridge: $BRIDGE_NAME"
nmcli connection up "$BRIDGE_NAME"

# Give the system a moment to establish the connection
sleep 3

# Step 6: Verify the bridge is working
print_header "Step 6: Verification"

# Check if bridge interface exists and is UP
if ip link show "$BRIDGE_NAME" &>/dev/null && ip link show "$BRIDGE_NAME" | grep -q "state UP"; then
	print_success "Bridge interface is UP"

	# Show bridge IP address
	BRIDGE_ADDR=$(ip -4 addr show "$BRIDGE_NAME" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
	if [[ -n "$BRIDGE_ADDR" ]]; then
		print_success "Bridge IP address: $BRIDGE_ADDR"
	else
		print_warning "Bridge is UP but has no IP address yet (may still be acquiring DHCP lease)"
	fi

	# Show which interfaces are attached to the bridge
	print_status "Bridge members:"
	ip link show master "$BRIDGE_NAME" | grep -oP '^\d+: \K[^:]+' | while read member; do
		echo "  - $member"
	done

else
	print_error "Bridge interface is not UP!"
	print_error "You may need to manually troubleshoot. Try:"
	print_error "  nmcli connection up '$BRIDGE_NAME'"
	exit 1
fi

# Step 7: Configure libvirt bridge network
print_header "Step 7: Configuring Libvirt Bridge Network"

# Create the libvirt network XML definition
# This tells libvirt about the bridge so VMs can use it
LIBVIRT_NETWORK="host-bridge"
NETWORK_XML="/tmp/${LIBVIRT_NETWORK}.xml"

cat >"$NETWORK_XML" <<EOF
<network>
  <name>${LIBVIRT_NETWORK}</name>
  <forward mode='bridge'/>
  <bridge name='${BRIDGE_NAME}'/>
</network>
EOF

print_status "Created libvirt network definition: $LIBVIRT_NETWORK"

# Check if this network already exists in libvirt
if virsh net-info "$LIBVIRT_NETWORK" &>/dev/null; then
	print_warning "Libvirt network '$LIBVIRT_NETWORK' already exists."
	read -p "Do you want to undefine and recreate it? (y/N): " recreate_net
	if [[ "$recreate_net" =~ ^[Yy]$ ]]; then
		virsh net-destroy "$LIBVIRT_NETWORK" 2>/dev/null || true
		virsh net-undefine "$LIBVIRT_NETWORK"
		print_status "Removed existing network definition"
	else
		print_status "Keeping existing network definition"
		rm "$NETWORK_XML"
		print_success "Bridge setup complete!"
		exit 0
	fi
fi

# Define the network in libvirt
print_status "Defining libvirt network..."
virsh net-define "$NETWORK_XML"

# Start the network
print_status "Starting libvirt network..."
virsh net-start "$LIBVIRT_NETWORK"

# Set it to autostart
print_status "Enabling autostart for libvirt network..."
virsh net-autostart "$LIBVIRT_NETWORK"

# Clean up temporary XML file
rm "$NETWORK_XML"

print_success "Libvirt network '$LIBVIRT_NETWORK' configured successfully"

# Final summary
print_header "Setup Complete!"

echo "Bridge network has been successfully configured!"
echo ""
echo "Summary:"
echo "  Physical interface: $PHYSICAL_IFACE"
echo "  Bridge interface: $BRIDGE_NAME"
echo "  Bridge IP: ${BRIDGE_ADDR:-Acquiring...}"
echo "  Libvirt network: $LIBVIRT_NETWORK"
echo ""
echo "Next steps:"
echo "  1. Use the 'vm-to-bridge.sh' script to convert your VMs to use this bridge"
echo "  2. Your VMs will receive IP addresses directly from your router"
echo "  3. VMs will be accessible from anywhere on your LAN at their assigned IPs"
echo ""
print_success "All done! Your system is now configured for bridge networking."

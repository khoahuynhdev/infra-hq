#!/usr/bin/env bash

set -e

sudo dnf update

sudo systemctl stop swap-create@zram0
sudo dnf remove zram-generator-defaults

sudo systemctl disable --now firewalld

sudo dnf install iptables iproute-tc

sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

sudo dnf install cri-o1.33 containernetworking-plugins

sudo dnf install kubernetes1.33 kubernetes1.33-kubeadm kubernetes1.33-client

sudo systemctl enable --now crio

sudo kubeadm config images pull

sudo systemctl enable --now kubelet

#!/bin/bash
# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Define variables
VM_NAME="kde-neon-new"
# DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
# DISK_SIZE="100G"
ISO_PATH="/home/tripham/Dev/QEMU_Machines/kdeneon-user/neon-user-20240917-0204.iso"

echo -e "${LIGHTBLUE}Creating kde-neon-new VM ...${NOCOLOR}"

# Create the disk image
# sudo qemu-img create -f qcow2 "${DISK_PATH}" "${DISK_SIZE}"

virt-install \
  --debug \
	--name "${VM_NAME}" \
  --arch x86_64 \
	--memory 12288 \
	--vcpus 4,sockets=4,cores=1,threads=1 \
	--cpu host-model,topology.sockets=4,topology.cores=1,topology.threads=1 \
	--machine q35 \
	--boot uefi \
	--disk size=100,bus=virtio,cache=writeback,format=qcow2 \
	--cdrom "${ISO_PATH}" \
	--graphics clipboard.copypaste=yes \
	--video virtio \
	--input tablet,bus=usb \
	--rng /dev/urandom \
	--serial pty \
	--console pty \
	--channel spicevmc \
  --virt-type kvm \
	--features smm=on \
	--clock offset=localtime \
  --qemu-commandline="-overcommit mem-lock=off" \
  --qemu-commandline="-object memory-backend-memfd,id=mem1,share=on,size=12G" \
  --qemu-commandline="-machine dump-guest-core=off,mem-merge=on,smm=on,nvdimm=off,hmat=on,memory-backend=mem1,kvm-shadow-mem=256000000,kernel_irqchip=on" \
  --qemu-commandline="-k de" \
  --qemu-commandline="-msg timestamp=on" \
  --connect qemu:///system \
	--osinfo detect=on,name=linux2022 \
  --filesystem=/home/tripham/Downloads/,host_downloads,driver.type=virtiofs \
  --memorybacking=source.type=memfd,access.mode=shared \
	--noautoconsole 

echo -e "${LIGHTBLUE}Change mode of '/var/lib/libvirt/qemu/nvram/kde-neon-new_VARS.fd' for running by 'ubuntu_gl' script.${NOCOLOR}"
sudo chmod a+rw /var/lib/libvirt/qemu/nvram/kde-neon-new_VARS.fd
echo -e "${LIGHTBLUE}Change mode of '/var/lib/libvirt/images/kde-neon-new.qcow2' for running by 'ubuntu_gl' script.${NOCOLOR}"
sudo chmod a+rw /var/lib/libvirt/images/kde-neon-new.qcow2

echo -e "${LIGHTBLUE}- The kde-neon VM is running in the background. Please start 'virt-manager' to continue the OS installation.${NOCOLOR}"
echo -e "${LIGHTBLUE}- After finishing the OS installation. Please use the following script to setup shared folder on the guest VM.${NOCOLOR}"
echo -e "${LIGHTGREEN}
mkdir -p ~/host_downloads

sudo tee -a /etc/fstab <<EOF
host_downloads /home/tripham/host_downloads virtiofs defaults 0 0
EOF
${NOCOLOR}"

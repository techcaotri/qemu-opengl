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

run_uniclip() {
	# Kill all uniclip processes
	killall uniclip

	# Define the log file path
	LOG_FILE="/tmp/uniclip_output.log"

	# Run uniclip in the background and redirect output to the log file
	uniclip -d -p 5100 >"$LOG_FILE" 2>&1 &

	# Capture the process ID
	UNICLIP_PID=$!

	echo "uniclip server is running in the background with PID $UNICLIP_PID"

	# Function to extract IP:Port from the log file
	extract_ip_port() {
		grep "Run \`uniclip" "$LOG_FILE" | awk -F'`' '{print $2}' | awk '{print $2}'
	}

	# Wait for the IP:Port information to appear in the log file
	echo "Waiting for IP:Port information..."
	for i in {1..30}; do
		IP_PORT=$(extract_ip_port)
		if [ -n "$IP_PORT" ]; then
			echo "Extracted IP:Port is $IP_PORT"
			uniclip "$IP_PORT" &
			break
		fi
		sleep 1
	done

	# Check if we successfully extracted the IP:Port
	if [ -z "$IP_PORT" ]; then
		echo "Failed to extract IP:Port within 30 seconds. Check the log file at $LOG_FILE"
	fi

	echo "uniclip server is still running in the background. To stop it, use: kill $UNICLIP_PID"
}

BOOT_BIN=/usr/bin/qemu-system-x86_64
NETNAME=ubuntu
# MAC=$(grep -e "${NETNAME}=" macs.txt |cut -d"=" -f 2)
HOSTNAME=${NETNAME}
MEM=24G
DP=sdl,gl=on
MTYPE=q35,usb=off,dump-guest-core=off,pflash0=libvirt-pflash0-format,pflash1=libvirt-pflash1-format,mem-merge=on,smm=on,vmport=off,nvdimm=off,hmat=on,memory-backend=mem1
ACCEL=accel=kvm,kvm-shadow-mem=256000000,kernel_irqchip=on
UUID="$(uuidgen)"
CPU=8,sockets=4,cores=2,threads=1
BIOS=${SCRIPT_DIR}/kde-neon_VARS.fd
# BIOS=/usr/share/OVMF/OVMF_VARS_4M.ms.fd
ISODIR=/applications/OS/isos
VMDIR=/virtualisation
VARS=${VMDIR}/ovmf/OVMF_VARS-${NETNAME}.fd

args=(
	-uuid ${UUID}
	-name ${NETNAME},process=${NETNAME}
	# -pidfile "/tmp/${NETNAME}/${NETNAME}.pid"
	-no-user-config
	-cpu host,vmx=on,hypervisor=on,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vendor-id=1234567890,kvm=on
	-smp ${CPU}
	-m ${MEM}
	# -smbios type=2,manufacturer="oliver",product="${NETNAME}starter",version="0.1",serial="0xDEADBEEF",location="github.com",asset="${NETNAME}"
	# -bios ${BIOS}
	# -drive if=pflash,format=raw,file=${BIOS}
	-blockdev '{"driver":"file","filename":"/usr/share/OVMF/OVMF_CODE_4M.ms.fd","node-name":"libvirt-pflash0-storage","auto-read-only":true,"discard":"unmap"}'
	-blockdev '{"node-name":"libvirt-pflash0-format","read-only":true,"driver":"raw","file":"libvirt-pflash0-storage"}'
	-blockdev '{"driver":"file","filename":"'$SCRIPT_DIR'/kde-neon_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"}'
	-blockdev '{"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"}'
	-machine ${MTYPE},${ACCEL}
	-mem-prealloc
	-rtc base=localtime
	-drive file=/var/lib/libvirt/images/kde-neon-sparse.qcow2,if=virtio,format=qcow2,cache=writeback
	-enable-kvm
	-object memory-backend-memfd,id=mem1,share=on,size=${MEM}
	-overcommit mem-lock=off
	-object rng-random,id=objrng0,filename=/dev/urandom
	-device virtio-rng-pci,rng=objrng0,id=rng0
	-device virtio-serial-pci
	-device virtio-vga-gl,xres=2560,yres=1440
	-vga none
	-display ${DP}
	-usb
	-device usb-tablet
	-monitor stdio
	-k de
	-global ICH9-LPC.disable_s3=1
	-global ICH9-LPC.disable_s4=1
	-device ide-cd,bus=ide.0,id=sata0-0-0
	# -audiodev pa,id=hda,server=/run/user/1000/pulse/native
	# -device ich9-intel-hda,bus=pcie.0,addr=0x1b
	# -device hda-micro,audiodev=hda
  -device ich9-intel-hda,id=sound0,bus=pcie.0,addr=0x1b
  -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0
  -global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1
	-device virtio-net,netdev=nic
	-netdev user,hostname=kdeneon-user,hostfwd=tcp::22220-:22,id=nic
	-chardev pty,id=charserial0
	-device isa-serial,chardev=charserial0,id=serial0
	-chardev spicevmc,id=charchannel1,name=vdagent
	-chardev null,id=chrtpm
  -chardev socket,id=char0,path=/tmp/vhostqemu
  -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=host_downloads
	-msg timestamp=on
)

# check if the bridge is up, if not, dont let us pass here
# if [[ $(ip -br l | awk '$1 !~ "lo|vir|wl" { print $1 }') != *tap0-${NETNAME}* ]]; then
#     echo "bridge is not running, please start bridge interface"
#     exit 1
# fi

#create tmp dir if not exists
if [ ! -d "/tmp/${NETNAME}" ]; then
	mkdir /tmp/${NETNAME}
fi

# get tpm going
# exec swtpm socket --tpm2 --tpmstate dir=/tmp/${NETNAME} --terminate --ctrl type=unixio,path=/tmp/${NETNAME}/swtpm-sock-${NETNAME} --daemon &

echo -e "${LIGHTBLUE}Start VirtioFS Daemon virtiofsd for sharing Downloads directory ...${NOCOLOR}"
sudo rm /tmp/vhostqemu
sudo /usr/lib/qemu/virtiofsd --socket-path=/tmp/vhostqemu --socket-group=tripham -o source=/home/tripham/Downloads/ -o allow_direct_io -o cache=always &

run_uniclip

echo -e "${LIGHTBLUE}Start the VM using QEMU ...${NOCOLOR}"
echo ${BOOT_BIN} "${args[@]}"
GTK_BACKEND=x11 GDK_BACKEND=x11 QT_BACKEND=x11 VDPAU_DRIVER="nvidia" ${BOOT_BIN} "${args[@]}"

exit 0

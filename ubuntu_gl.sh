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

BOOT_BIN=/usr/bin/qemu-system-x86_64
NETNAME=ubuntu
# MAC=$(grep -e "${NETNAME}=" macs.txt |cut -d"=" -f 2)
HOSTNAME=${NETNAME}
MEM=12G
DP=sdl,gl=on
MTYPE=pc-q35-6.2,accel=kvm,dump-guest-core=off,mem-merge=on,smm=on,vmport=off,nvdimm=off,hmat=on,memory-backend=mem1
ACCEL=accel=kvm,kvm-shadow-mem=256000000,kernel_irqchip=on
UUID="$(uuidgen)"
CPU=4,sockets=4,cores=1,threads=1
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
	-blockdev '{"driver":"file","filename":"'${SCRIPT_DIR}'/kde-neon_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"}'
	-blockdev '{"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"}'
	-machine pc-q35-7.0,usb=off,vmport=off,smm=on,dump-guest-core=off,pflash0=libvirt-pflash0-format,pflash1=libvirt-pflash1-format,memory-backend=pc.ram
	-mem-prealloc
	-rtc base=localtime
	-drive file=/var/lib/libvirt/images/kde-neon.img,if=virtio,format=raw,cache=writeback
	-enable-kvm
	-object memory-backend-memfd,id=mem1,share=on,size=${MEM}
	-machine ${MTYPE},${ACCEL}
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
	-audiodev pa,id=snd0,server=localhost -device AC97,audiodev=snd0
	-device virtio-net,netdev=nic
	-netdev user,hostname=kdeneon-user,hostfwd=tcp::22220-:22,hostfwd=tcp::5100-:5100,id=nic
	-chardev pty,id=charserial0
	-device isa-serial,chardev=charserial0,id=serial0
	-device virtio-serial
	-chardev spicevmc,id=vdagent,debug=1,name=vdagent
	-device virtserialport,chardev=vdagent,name=com.redhat.spice.0
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

echo -e "${LIGHTBLUE}Start PulseAudio audio server...${NOCOLOR}"
pulseaudio --start --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

echo -e "${LIGHTBLUE}Start VirtioFS Daemon virtiofsd for sharing Downloads directory ...${NOCOLOR}"
sudo rm -f /tmp/vhostqemu
sudo /usr/lib/qemu/virtiofsd --socket-path=/tmp/vhostqemu --socket-group=tripham -o source=/home/tripham/Downloads/ -o allow_direct_io -o cache=always &

echo ${BOOT_BIN} "${args[@]}"
GTK_BACKEND=x11 GDK_BACKEND=x11 QT_BACKEND=x11 VDPAU_DRIVER="nvidia" ${BOOT_BIN} "${args[@]}"

exit 0

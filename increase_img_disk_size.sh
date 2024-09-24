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

echo -e "${LIGHTBLUE}Current disk info of kde-neon ...${NOCOLOR}"
sudo qemu-img info /var/lib/libvirt/images/kde-neon.img

read -p "Do you want to increase the disk size of kde-neon by 100GB ?" choice
case "$choice" in
y | Y)
	sudo qemu-img resize /var/lib/libvirt/images/kde-neon.img +100G
	echo -e "${LIGHTBLUE}New disk info of kde-neon ...${NOCOLOR}"
	sudo qemu-img info /var/lib/libvirt/images/kde-neon.img
	;;
n | N | *)
	echo "Ignore and exit."
  exit
	;;
esac

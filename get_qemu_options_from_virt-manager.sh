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


echo -e "${LIGHTBLUE}Get QEMU command line options from virt-manager's kde-neon VM ...${NOCOLOR}"
virsh dumpxml kde-neon > desktop_kde-neon_vm_config.xml
virsh domxml-to-native qemu-argv desktop_kde-neon_vm_config.xml 2>&1 | tee desktop_kde-neon_vm_config.txt
echo -e "${LIGHTBLUE}Formatting the output file: desktop_kde-neon_vm_config.txt ...${NOCOLOR}"
sed -i 's/ -/\n-/g' desktop_kde-neon_vm_config.txt

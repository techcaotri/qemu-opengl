# qemu-opengl
Playground for QEMU with OpenGL, Audio, Shared Folder, Copy &amp; Paste, etc.

## Steps
1. Install the prerequisite softwares, **virt-manager**, **qemu** version 7.0, etc.
 ```
 $ ./install_software_dependecies.sh
 ```
2. Create the supported VM, currently support Ubuntu 24.04 and KDE Neon user version 20240917-0204
 ```
 # create Ubuntu 24.04 VM
 $ ./create_ubuntu-24-04_vm.sh
 # or create KDE Neon VM
 $ ./create_kde-neon-new_vm.sh
 ```
3. Open the **virt-manager** app to continue the OS installation
4. There're 2 ways to run the VMs:
 + Use **SPICE** with `remote-viewer.sh` script to run the VM with client-server displaying mode.
 This mode supports both file sharing and clipboard sharing between host and guest VMs. However, the latency is a little bit high but acceptable.
 + Use the `ubuntu-24-04-sparse-gl.sh` script to run the VM with SDL OpenGL mode. This mode gives the best latency performance.
 However, it doesn't support clipboard sharing out-of-the-box, only file sharing. Still, the clipboard sharing could also be achieved using the `uniclip` tool.

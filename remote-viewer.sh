#!/bin/bash

NETNAME=ubuntu
GTK_BACKEND=x11 GDK_BACKEND=x11 QT_BACKEND=x11 VDPAU_DRIVER="nvidia" /usr/bin/remote-viewer spice+unix:///tmp/$NETNAME/spice.sock 

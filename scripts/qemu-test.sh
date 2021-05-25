#!/bin/zsh

SCRIPT="$(basename "$0")"
QEMU=qemu-system-x86_64
QKVM="-enable-kvm"
QNET="-netdev user,id=unet0,hostfwd=tcp::9200-:22 -device e1000,netdev=unet0"
QHDA=""
QMEM=8

zparseopts -D -E -a opts -- help n nokvm nonet hda:

if ((${opts[(I)-help]} || $# > 1)); then
    echo "Script for testing SystemRescue images using QEMU."
    echo "Usage: $SCRIPT [-help] [-n] [-nokvm] [-nonet] [-hda <qcow_image>] <iso_image>"
    exit 1
fi

if ((${opts[(I)-nokvm]})); then
	QKVM=""
fi

if ((${opts[(I)-nonet]})); then
	QNET=""
fi

if ((${opts[(I)-hda]})); then
	QHDA="-hda ${opts[ ${opts[(I)-hda]} + 1 ]}"
fi

if ((${opts[(I)-n]})); then
	QEMU="echo $QEMU"
	printf "Dry run:\n"
fi

${=QEMU} -m ${QMEM}G ${QKVM} ${=QNET} ${=QHDA} -cdrom "$1"

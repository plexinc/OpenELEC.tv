#!/bin/bash

IMAGE_SIZE=256
IMAGE_FILE="install.image"
INSTALL_DEVICE=$(losetup -f)

echo "Using device: ${INSTALL_DEVICE}"

if [ -f "${IMAGE_FILE}" ];then
	echo "Image exists, deleting"
	rm -rf "${IMAGE_FILE}"
fi

dd if=/dev/zero of="${IMAGE_FILE}" bs=1024 seek=$((${IMAGE_SIZE} * 1024)) count=0

losetup -f "${IMAGE_FILE}"

#export RECOVERY_MIN=15
AUTOMATED_INSTALL=true RECOVERY_MIN=30 INSTALL_DEVICE=${INSTALL_DEVICE} INSTALL_ELEC=false ./atv_installer.sh

# create data partition
DRIVE_END=$(parted -s "${INSTALL_DEVICE}" print -m | egrep "^${INSTALL_DEVICE}" | cut -d : -f 2)

DATA_START=$((35 + 30))

parted -s "${INSTALL_DEVICE}" mkpart primary fat32 "${DATA_START}MB" "${DRIVE_END}MB" || exit

partprobe "${INSTALL_DEVICE}"
blockdev --rereadpt "${INSTALL_DEVICE}"
sync

mkfs.msdos -F 32 -n installer "${INSTALL_DEVICE}p3" &>/dev/null || exit

partprobe "${INSTALL_DEVICE}"
blockdev --rereadpt "${INSTALL_DEVICE}"
sync

losetup -d ${INSTALL_DEVICE}


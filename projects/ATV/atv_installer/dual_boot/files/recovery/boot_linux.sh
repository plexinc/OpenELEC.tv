#!/bin/bash

BOOT_DEVICE="/dev/sdb"
FLASH_PARTITION_NUMBER="3"
FLASH_PARTITION="${BOOT_DEVICE}${FLASH_PARTITION_NUMBER}"
STORAGE_PARTITION_NUMBER="4"
STORAGE_PARTITION="${BOOT_DEVICE}${STORAGE_PARTITION_NUMBER}"

# /dev/sda\n/dev/sdb\n...
DRIVES=$(parted -l -m | egrep "^/dev/sd" | cut -d ":" -f 1)
for DRIVE in $DRIVES;do
	PARTITIONS=$(parted -s "${DRIVE}" print -m | grep -e "^[0-9]" | cut -d ":" -f 1)
	for PARTITION in ${PARTITIONS};do
		FILESYSTEM=$(parted -s "${DRIVE}" print -m | grep -e "^[0-9]" | grep -e "^${PARTITION}" | cut -d ":" -f 5 | grep "hfs")
		if [ -n "${FILESYSTEM}" ];then
			fsck.hfsplus "${DRIVE}${PARTITION}"
		fi
	done
done

BOOT_DIR="/mnt/boot"

mkdir -p "${BOOT_DIR}"
mount "${FLASH_PARTITION}" "${BOOT_DIR}"

cd "${BOOT_DIR}"
./kexec.sh

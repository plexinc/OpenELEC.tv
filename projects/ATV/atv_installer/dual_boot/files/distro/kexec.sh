#!/bin/bash

SCRIPT_DIR=$(dirname $0)
cd "${SCRIPT_DIR}"

BOOT_DEVICE="/dev/sdb"
FLASH_PARTITION_NUMBER="3"
STORAGE_PARTITION_NUMBER="4"

FLASH_PARTITION="${BOOT_DEVICE}${FLASH_PARTITION_NUMBER}"
STORAGE_PARTITION="${BOOT_DEVICE}${STORAGE_PARTITION_NUMBER}"

EXTRA_CMD_LINE=" "

echo "Booting Openelec.tv..."

if [ -f "./video_driver" ];then
	VIDEO_DRIVER=$(cat ./video_driver)
else
	VIDEO_DRIVER="nouveau"
fi

# nvidia style
if [ "${VIDEO_DRIVER}" == "nvidia" ];then
	EXTRA_CMD_LINE="${EXTRA_CMD_LINE} nouveau.blacklist=1 nouveau.modeset=0"
fi

# nouveau style
kexec -l "./KERNEL" --command-line="boot=${FLASH_PARTITION} disk=${STORAGE_PARTITION} quiet ${EXTRA_CMD_LINE}"
kexec -e

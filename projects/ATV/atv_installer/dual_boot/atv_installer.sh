#!/bin/bash

## Basic Variables
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=$(cd `dirname $0`;pwd);
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"
CALLED_AS=$0
CALLED_AS_FULL="$0 $@"
START_PWD=`pwd`
TOTAL_POSITIONAL_PARAMETERS=$#
FULL_POSITIONAL_PARAMETER_STRING=$@
TOTAL_PARAMETERS=0
TOTAL_OPTIONS=0

## Configuration
#MIN_OPTIONS=1
#MAX_OPTIONS=10
#MIN_PARAMETERS=1
#MAX_PARAMETERS=1


## App Variables
FILES_DIR="${SCRIPT_DIR}/files"
# name of the bootlogo to be used in com.apple.Boot.plist
BOOTLOGO_FILENAME="BootLogoOpenElec.png"
# contains the partition number that will next be created - gets bumped after each creation
CURRENT_PARTITION_NUMBER=1
# flags to be appended to the com.apple.Boot.plist file
EXTRA_APPLE_KERNEL_FLAGS="quiet"
# flags appended to the kexec --command-line arg for the kexec.sh script
EXTRA_KERNEL_FLAGS=""
CREATE_EFI_PARTITION="true"
CREATE_OSBOOT_PARTITION="false"

VIDEO_DRIVER="nouveau"

usage(){
	echo "Usage: " "${SCRIPT_NAME}";
}

kill_pid(){
	local PID=$1
	local SIGNAL=$2
	if [ -n "${SIGNAL}" ];then
		SIGNAL=15
	fi
	kill -s "${SIGNAL}" "${PID}" &> /dev/null
}

kill_pids(){
	local PIDS=$1
	local SIGNAL=$2
	if [ -n "${SIGNAL}" ];then
		SIGNAL=15
	fi
	for PID in $PIDS;do
		kill_pid "${PID}" "${SIGNAL}"
	done
}

pid_is_running(){
	local PID=${1}
	ps "${PID}" > /dev/null
	return $?
}

wait_for_pid(){
	local PID=${1}
	local WAIT=${2-5}
	local ECHO_DOT=${3-false}
	pid_is_running "${PID}"
	while [ $? -eq 0 ];do
		sleep "${WAIT}"
		if [ "${ECHO_DOT}" = "true" ];then
			echo -n ".";
		fi
		pid_is_running "${PID}"
	done
}

cleanup(){
	local EXIT_STATUS=$1
	if [ -n "${EXIT_STATUS}" ];then
		EXIT_STATUS=0
	fi
	kill_pids "${SCRIPT_PIDS}" "15"
	exit $EXIT_STATUS;
}

trap cleanup 1 2 3 15

silence_output(){
	exec > /dev/null 2>&1
}

spawn_process(){
	local COMMAND=$1
	local PID
	eval "${COMMAND} &"
	PID=$!
	SCRIPT_PIDS=("${SCRIPT_PIDS[@]}" ${PID})
	SPAWNED_PID="${PID}"
}

echo_exec_info(){
	echo "Script name: ${SCRIPT_NAME}"
	echo "Script directory: ${SCRIPT_DIR}"
	echo "Script path: ${SCRIPT_PATH}"
	echo "Called as: ${CALLED_AS}"
	echo "Called as full: ${CALLED_AS_FULL}"
	echo "Called from: ${START_PWD}"
	echo "Total options: ${TOTAL_OPTIONS}"
	echo "Total parameters: ${TOTAL_PARAMETERS}"
	echo "Total positional parameters: ${TOTAL_POSITIONAL_PARAMETERS}"
	echo "Full options/parameter string: ${FULL_POSITIONAL_PARAMETER_STRING}"
}

to_upper(){
	local STRING=${1}
	if [ -n "${STRING}" ];then
		STRING=$(echo "${STRING}" | tr "[:lower:]" "[:upper:]")
		echo "${STRING}"
	fi
}

to_lower(){
	local STRING=${1}
	if [ -n "${STRING}" ];then
		STRING=$(echo "${STRING}" | tr "[:upper:]" "[:lower:]")
		echo "${STRING}"
	fi
}

yes_no(){
	local MESSAGE=${1-Would you like to continue?}
	local DEFAULT=${2-Y}
	local ANSWER
	local OPTIONS
	
	DEFAULT=`to_upper "${DEFAULT}"`
	
	if [ "${DEFAULT}" != "Y" ] && [ "${DEFAULT}" != "N" ];then
		DEFAULT="Y"
	fi
	
	if [ "${DEFAULT}" = "Y" ];then
		OPTIONS="Y/n"
	else
		OPTIONS="y/N"
	fi
	
	echo -n "${MESSAGE} [${OPTIONS}] "
	read ANSWER
	ANSWER=`to_upper "${ANSWER}"`
	if [ -z ${ANSWER} ];then
		if [ "${DEFAULT}" = "Y" ];then
			return 0
		else
			return 1
		fi
	fi
	
	while [ "${ANSWER}" != "Y" ] && [ "${ANSWER}" != "N" ];do
		if [ -z ${ANSWER} ];then
			if [ "${DEFAULT}" = "Y" ];then
				return 0
			else
				return 1
			fi
		fi
		echo "Invalid response.  Try again."
		echo -n "${MESSAGE} [${OPTIONS}] "
		read ANSWER
		ANSWER=`to_upper "${ANSWER}"`
	done
	
	if [ "${ANSWER}" = "Y" ];then
		return 0
	else
		return 1
	fi
}

write_to_stderr(){
	local STRING=${1}
	if [ -n "${STRING}" ];then
		echo "${STRING}" >&2
	fi
}

rm_file(){
	local FILE=${1}
	if [ -O "${FILE}" ] || [ -w "${FILE}" ];then
		rm -rf "${FILE}"
		return $?
	else
		return 1
	fi
}

app_in_path(){
	local APP=${1}
	which "${APP}" &> /dev/null
	if [ $? -eq 0 ];then
		return 0
	else
		return 1
	fi
}

array_remove_value(){
	local ARRAY=${1}
	local VALUE=${2}
	local NEWARRAY
	local AVALUE
	declare -c NEWARRAY
	if [ -z "${ARRAY}" ];then
		echo ""
	fi
	for AVALUE in ${ARRAY};do
		if [ "${AVALUE}" != "${VALUE}" ];then
			NEWARRAY=("${NEWARRAY[@]}" "${AVALUE}")
		fi
	done
	echo "${NEWARRAY[@]}"
}

array_count(){
	local ARRAY=${1}
	echo ${#ARRAY[@]}
}

parameter_validation(){
	if [ -n "${MIN_OPTIONS}" ] && [ ${TOTAL_OPTIONS} -lt ${MIN_OPTIONS} ];then
		echo "Not enough options"
		usage
		exit 1
	fi

	if [ -n "${MIN_PARAMETERS}" ] && [ ${TOTAL_PARAMETERS} -lt ${MIN_PARAMETERS} ];then
		echo "Not enough parameters"
		usage
		exit 1
	fi

	if [ -n "${MAX_OPTIONS}" ] && [ ${TOTAL_OPTIONS} -gt ${MAX_OPTIONS} ];then
		echo "Too many options"
		usage
		exit 1
	fi

	if [ -n "${MAX_PARAMETERS}" ] && [ ${TOTAL_PARAMETERS} -gt ${MAX_PARAMETERS} ];then
		echo "Too many parameters"
		usage
		exit 1
	fi
}

read_input(){
	local MESSAGE="${1}"
	if [ -n "${MESSAGE}" ];then
		echo -n "${MESSAGE}"
	fi
	read INPUT
}

write_error(){
	local MESSAGE=$1
	echo "ERROR: ${MESSAGE}"
}

write_warning(){
	local MESSAGE=$1
	echo "WARNING: ${MESSAGE}"
}

get_partition_end(){
	local PARTITION=$1
	PARTITION_END=$(parted -s "${INSTALL_DEVICE}" print -m | egrep "^${PARTITION}" | cut -d ":" -f 3)
	strip_alpha_characters "${PARTITION_END}"
	PARTITION_END="${STRIPPED}"
}

ask_for_install_device(){
	echo "Available Devices..."
	echo ""
	parted -l | egrep "^Model|Disk"
	INPUT=""
	while [ -z "${INPUT}" ];do
		echo ""
		read_input "Please enter the install device (ie: /dev/sdX): "
	done
	INSTALL_DEVICE="${INPUT}"
}

validate_install_device(){
	local OUTPUT
	OUTPUT=$(fdisk -l "${INSTALL_DEVICE}" 2>/dev/null)
	#OUTPUT=$(parted -s "${INSTALL_DEVICE}" print)
	if [ -z "${OUTPUT}" ];then
		write_error "Device (${INSTALL_DEVICE}) appears to be invalid"
		exit 1
	else
		parted -s "${INSTALL_DEVICE}" print
	fi
	echo ""
	write_warning "All data will be wiped from the device above"
	yes_no "Would you like to continue using the device shown above" "N"
	if [ ! $? == 0 ];then
		echo "Goodbye!"
		exit 1
	fi
}

unmount_install_device_partitions(){
	local MOUNTS MOUNT DEVICE LINE SWAPS SWAP
	
	MOUNTS=()
	TMP_FILE=$(mktemp mounts.XXXXXX)
	cat /proc/mounts | egrep "^${INSTALL_DEVICE}" > "${TMP_FILE}"
	while read -r LINE;do
		DEVICE=$(echo "${LINE}" | cut -d " " -f 1)
		MOUNTS+=("${DEVICE}")
	done < "${TMP_FILE}"
	rm "${TMP_FILE}"
	
	if [ ${#MOUNTS[@]} -gt 0 ];then
		for MOUNT in "${MOUNTS[@]}";do
			echo "Unmounting '${MOUNT}'"
			umount "${MOUNT}"
		done
	fi
	
	SWAPS=()
	TMP_FILE=$(mktemp swaps.XXXXXX)
	cat /proc/swaps | egrep "^${INSTALL_DEVICE}" > "${TMP_FILE}"
	
	while read -r LINE;do
		DEVICE=$(echo "${LINE}" | cut -d " " -f 1)
		SWAPS+=("${DEVICE}")
	done < "${TMP_FILE}"
	rm "${TMP_FILE}"
	
	if [ ${#SWAPS[@]} -gt 0 ];then
		for SWAP in "${SWAPSS[@]}";do
			echo "Turning swap off '${SWAP}'"
			swapoff "${SWAP}"
		done
	fi
}

disk_sync(){
	partprobe "${INSTALL_DEVICE}"
	sync
}

prepare_install_device(){
	local PARTITION_NUMBERS PARTITION_NUMBER
	# zero /dev/sda first or pre-existing guid will not change
	#dd if=/dev/zero of="${INSTALL_DEVICE}" bs=4096 count=1M
	PARTITION_NUMBERS=($(parted -s "${INSTALL_DEVICE}" print | awk '/^ / {print $1}'))
	for PARTITION_NUMBER in "${PARTITION_NUMBERS[@]}";do
		write_to_stderr "Removing partion ${INSTALL_DEVICE}${PARTITION_NUMBER}"
		parted -s "${INSTALL_DEVICE}" rm "${PARTITION_NUMBER}"
	done
	
	# sync the system partition tables
	disk_sync
	# create initial gpt structures
	parted -s "${INSTALL_DEVICE}" mklabel gpt
}

create_base_partitions(){
	if [ "${CREATE_EFI_PARTITION}" == "true" ];then
		# create a 25MB "EFI" partition (starting at sector 40 is important)
		parted -s "${INSTALL_DEVICE}" mkpart primary fat32 40s 69671s
		parted -s "${INSTALL_DEVICE}" set "${CURRENT_PARTITION_NUMBER}" boot on
		CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	fi
	
	# create a 25MB "Recovery" partition
	if [ "${CURRENT_PARTITION_NUMBER}" -eq 1 ];then
		START="40s"
		END="69671s"
	else
		get_partition_end "$(( ${CURRENT_PARTITION_NUMBER} - 1 ))"
		START="${PARTITION_END}M"
		END=$(echo "${START} 25" | awk '{printf($1 + $2)}')
	fi
	parted -s "${INSTALL_DEVICE}" mkpart primary HFS "${START}" "${END}"
	parted -s "${INSTALL_DEVICE}" set "${CURRENT_PARTITION_NUMBER}" atvrecv on
	
	RECOVERY_PARTITION_NUMBER=${CURRENT_PARTITION_NUMBER}
	CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	
	if [ "${CREATE_OSBOOT_PARTITION}" == "true" ];then
		# create a 25MB "OSBoot" partition
		get_partition_end "$(( ${CURRENT_PARTITION_NUMBER} - 1 ))"
		START="${PARTITION_END}"
		END=$(echo "${START} 25" | awk '{printf($1 + $2)}')
		parted -s "${INSTALL_DEVICE}" mkpart primary HFS "${START}MB" "${END}MB"
		OSBOOT_PARTITION_NUMBER=${CURRENT_PARTITION_NUMBER}
		CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	fi
	# sync the system partition tables
	disk_sync
}

strip_alpha_characters(){
	local TEXT=$1
	STRIPPED=$(echo "${TEXT}" | sed 's/[^.0-9]//g')
}

create_extra_partitions(){
	local EXTRAS
	
	EXTRAS=(swap flash storage)
	
	for EXTRA in "${EXTRAS[@]}";do
		parted -s "${INSTALL_DEVICE}" print
		get_partition_end "$(( ${CURRENT_PARTITION_NUMBER} - 1 ))"
		case "${EXTRA}" in
			swap )
				yes_no "Would you like to create a swap partition (note that a swap *file* will be automaticlaly created for you if you omit the partiion)? " "N" || continue;
				
				SWAP_PARTITION_NUMBER=$CURRENT_PARTITION_NUMBER
				SWAP_START="${PARTITION_END}"
				SWAP_SIZE=""
				while [ -z "${SWAP_SIZE}" ];do
					read_input "Please specify desired swap size (in MB): "
					strip_alpha_characters "${INPUT}"
					SWAP_SIZE="${STRIPPED}"
				done
				SWAP_END=$(echo "${SWAP_START} ${SWAP_SIZE}" | awk '{printf($1 + $2)}')
				
				# create swap partiion and format it
				parted -s "${INSTALL_DEVICE}" mkpart primary linux-swap "${SWAP_START}MB" "${SWAP_END}MB" || exit
				disk_sync
				mkswap "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}"
				CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
				;;
			flash )
				FLASH_PARTITION_NUMBER=$CURRENT_PARTITION_NUMBER
				FLASH_START="${PARTITION_END}"
				FLASH_SIZE=""
				while [ -z "${FLASH_SIZE}" ];do
					read_input "Please specify desired flash partition size (in MB, 150 recommended): "
					strip_alpha_characters "${INPUT}"
					FLASH_SIZE="${STRIPPED}"
				done
				FLASH_END=$(echo "${FLASH_START} ${FLASH_SIZE}" | awk '{printf($1 + $2)}')
				
				# create flash partiion and format it
				parted -s "${INSTALL_DEVICE}" mkpart primary ext3 "${FLASH_START}MB" "${FLASH_END}MB" || exit
				disk_sync
				mkfs.ext3 -L "flash" "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}"
				fsck.ext3 "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}"
				mount "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}" "${FILES_DIR}/mnt/flash"
				CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
				;;
			storage )
				STORAGE_PARTITION_NUMBER=$CURRENT_PARTITION_NUMBER
				STORAGE_START="${PARTITION_END}"
				STORAGE_END=""
				while [ -z "${STORAGE_END}" ];do
					DRIVE_END=$(parted -s "${INSTALL_DEVICE}" print -m | egrep "^${INSTALL_DEVICE}" | cut -d : -f 2)
					read_input "Please specify desired END position of storage partition (recommended ${DRIVE_END}): "
					STORAGE_END="${INPUT}"
				done
				
				# create storage partiion and format it
				parted -s "${INSTALL_DEVICE}" mkpart primary ext3 "${STORAGE_START}MB" "${STORAGE_END}MB" || exit
				disk_sync
				mkfs.ext3 -L "storage" "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}"
				fsck.ext3 "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}"
				mount "${INSTALL_DEVICE}${CURRENT_PARTITION_NUMBER}" "${FILES_DIR}/mnt/storage"
				CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
				;;
			* )
				write_error "invalid extra partion '${EXTRA}'"
				exit 1
				;;
		esac
	done
	
}

format_base_partitions(){
	# format the partitions
	# we will let the LiveCD install setup swap
	if [ "${CREATE_EFI_PARTITION}" == "true" ];then
		mkfs.msdos -F 32 -n EFI "${INSTALL_DEVICE}1"
	fi
	
	
	mkfs.hfsplus -v Recovery "${INSTALL_DEVICE}${RECOVERY_PARTITION_NUMBER}"
	fsck.hfsplus "${INSTALL_DEVICE}${RECOVERY_PARTITION_NUMBER}"
	mount "${INSTALL_DEVICE}${RECOVERY_PARTITION_NUMBER}" "${FILES_DIR}/mnt/recovery"

	if [ "${CREATE_OSBOOT_PARTITION}" == "true" ];then
		mkfs.hfsplus -v OSBoot "${INSTALL_DEVICE}${OSBOOT_PARTITION_NUMBER}"
		fsck.hfsplus "${INSTALL_DEVICE}${OSBOOT_PARTITION_NUMBER}"
		mount "${INSTALL_DEVICE}${OSBOOT_PARTITION_NUMBER}" "${FILES_DIR}/mnt/osboot"
	fi
}

install_recovery(){
	if [ ! -f "${FILES_DIR}/recovery/${BOOTLOGO_FILENAME}" ];then
		cp -a "${FILES_DIR}/sources/${BOOTLOGO_FILENAME}" "${FILES_DIR}/recovery"
	fi
	# copy atv-bootloader over
	if [ "${CREATE_OSBOOT_PARTITION}" == "true" ];then
		cp -arp "${FILES_DIR}/recovery/"* "${FILES_DIR}/mnt/osboot/"
	fi
	cp -arp "${FILES_DIR}/recovery/"* "${FILES_DIR}/mnt/recovery/"
	disk_sync
}


install_vanilla_recovery(){
	# copy atv-bootloader over
	TMP=$(mktemp -d "recovery.XXXXXX")
	tar -zxvf "${FILES_DIR}/sources/recovery-0.6.tar.gz" -C "${TMP}"
	cp -arp "${FILES_DIR}/sources/boot.efi" "${TMP}/recovery/"
	if [ "${CREATE_OSBOOT_PARTITION}" == "true" ];then
		cp -arp "${TMP}/recovery/"* "${FILES_DIR}/mnt/osboot/"
	fi
	cp -arp "${TMP}/recovery/"* "${FILES_DIR}/mnt/recovery/"
	rm -rf "${TMP}"
	disk_sync
}

determine_boot_device(){
	yes_no "Will '${INSTALL_DEVICE}' be the internal drive on your ATV? "
	if [ $? -eq 0 ];then
		BOOT_DEVICE="/dev/sda"
	else
		BOOT_DEVICE="/dev/sdb"
	fi
}

create_flash_kexec_script(){
	cp -a "${FILES_DIR}/sources/kexec.sh" "${FILES_DIR}/distro/kexec.sh"
	KEXEC_FILE="${FILES_DIR}/distro/kexec.sh"
	chmod +x "${KEXEC_FILE}"
	sed -i "s:%boot_device%:${BOOT_DEVICE}:" "${KEXEC_FILE}"
	sed -i "s:%flash_partition_number%:${FLASH_PARTITION_NUMBER}:" "${KEXEC_FILE}"
	sed -i "s:%storage_partition_number%:${STORAGE_PARTITION_NUMBER}:" "${KEXEC_FILE}"
	sed -i "s:%extra_kernel_flags%:${EXTRA_KERNEL_FLAGS}:" "${KEXEC_FILE}"
}

setup_boot_scripts(){
	cp -a "${FILES_DIR}/sources/com.apple.Boot.plist" "${FILES_DIR}/recovery"
	cp -a "${FILES_DIR}/sources/boot_linux.sh" "${FILES_DIR}/recovery"
	
	# com.apple.Boot.plist
	sed -i "s:%bootlogo%:${BOOTLOGO_FILENAME}:" "${FILES_DIR}/recovery/com.apple.Boot.plist"
	sed -i "s:%extra_kernel_flags%:${EXTRA_APPLE_KERNEL_FLAGS}:" "${FILES_DIR}/recovery/com.apple.Boot.plist"
	
	# boot_linux.sh
	sed -i "s:%boot_device%:${BOOT_DEVICE}:" "${FILES_DIR}/recovery/boot_linux.sh"
	sed -i "s:%flash_partition_number%:${FLASH_PARTITION_NUMBER}:" "${FILES_DIR}/recovery/boot_linux.sh"
	sed -i "s:%storage_partition_number%:${STORAGE_PARTITION_NUMBER}:" "${FILES_DIR}/recovery/boot_linux.sh"
	chmod +x "${FILES_DIR}/recovery/boot_linux.sh"
}

install_flash(){
	echo "${VIDEO_DRIVER}" > "${FILES_DIR}/distro/video_driver"
	cp -arp "${FILES_DIR}/distro/"* "${FILES_DIR}/mnt/flash"
}

install_storage(){
	#cp -a "${FILES_DIR}/sources" "${FILES_DIR}/mnt/storage"
	echo "make this sane"
}

final_cleanup(){
	echo ""
	echo "Congrats!  You are almost finished"
	echo "We just have a few more items to clean up"
	echo "Please be patient as this may take some time..."
	chown -R root:root "${FILES_DIR}/mnt"
	disk_sync
	unmount_install_device_partitions
	echo "Phew! ALL DONE!  That wasn't very difficult was it?"
	echo "It's now safe to remove your device and connect it to the ATV"
}

main(){
	
	if [ $UID != 0 ];then
		echo "you *must* run this as root"
		usage
		exit 1
	fi
	
	if [ -z "${INSTALL_DEVICE}" ];then
		ask_for_install_device
	fi
	validate_install_device
	unmount_install_device_partitions
	prepare_install_device
	create_base_partitions
	format_base_partitions
	echo ""
	echo "Recovery image created successfully!"
	echo ""
	yes_no "Would you like to also install OpenElec.tv? " "Y"
	if [ $? -eq 0 ];then
		RECOVERY_INSTALL_ONLY="false"
	else
		RECOVERY_INSTALL_ONLY="true"
	fi
		
	if [ "${RECOVERY_INSTALL_ONLY}" == "true" ];then
		install_vanilla_recovery
	else
		create_extra_partitions
		determine_boot_device
		create_flash_kexec_script
		setup_boot_scripts
		install_recovery
		install_flash
		install_storage
	fi
	final_cleanup
	exit 0
}

#Parse options/parameters
while [ "$1" != "" ]; do
	#Options should always come first before parameters
	if [ "${1:0:1}" = "-" ];then
		TOTAL_OPTIONS=$(($TOTAL_OPTIONS + 1))
		case $1 in
			-f | --file )			shift
									filename=$1
									;;
			-i | --interactive )	interactive=1
									;;
			-h | --help )			usage
									exit
									;;
			* )						echo "Invalid option: " ${1}
									usage
									exit 1
		esac
	#Parameters always at the end
	else
		TOTAL_PARAMETERS=$#
		#FILE=$1
		#FILE2=$3
		#...
		#Clean them all up if desired
		while [ "$1" != "" ]; do
			shift;
		done
		break;
	fi
	shift
done

#echo_exec_info
#parameter_validation
main

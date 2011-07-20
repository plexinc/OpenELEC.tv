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
THIRDPARTY_DIR="${SCRIPT_DIR}/3rdparty"
TARGET_DIR="${SCRIPT_DIR}/target"
# name of the bootlogo to be used in com.apple.Boot.plist
BOOTLOGO_FILENAME="BootLogoOpenElec.png"
# contains the partition number that will next be created - gets bumped after each creation
CURRENT_PARTITION_NUMBER=1

# flags appended to the kexec --command-line arg for the kexec.sh script
EXTRA_KERNEL_FLAGS=""

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

strip_alpha_characters(){
	local TEXT=$1
	STRIPPED=$(echo "${TEXT}" | sed 's/[^.0-9]//g')
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
	parted -s -l | egrep "^Model|Disk" | sed 'n;G;'
	INPUT=""
	while [ -z "${INPUT}" ];do
		echo ""
		read_input "Please enter the install device (ie: /dev/sdX): "
		echo ""
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
	echo ""
	yes_no "Would you like to continue using the device shown above" "N"
	if [ ! $? == 0 ];then
		echo "Goodbye!"
		exit 1
	fi
}

unmount_install_device_partitions(){
	local MOUNTS MOUNT DEVICE LINE SWAPS SWAP
	
	MOUNTS=()
	TMP_FILE=$(mktemp "/tmp/mounts.XXXXXX")n
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
	TMP_FILE=$(mktemp "/tmp/swaps.XXXXXX")
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
	blockdev --rereadpt "${INSTALL_DEVICE}"
	sync
}

prepare_install_device(){
	local PARTITION_NUMBERS PARTITION_NUMBER
	# zero /dev/sda first or pre-existing guid will not change
	#dd if=/dev/zero of="${INSTALL_DEVICE}" bs=4096 count=1M
	PARTITION_NUMBERS=($(parted -s "${INSTALL_DEVICE}" print | awk '/^ / {print $1}'))
	for PARTITION_NUMBER in "${PARTITION_NUMBERS[@]}";do
		write_to_stderr "Removing partion ${INSTALL_DEVICE}${PARTITION_PREFIX}${PARTITION_NUMBER}"
		parted -s "${INSTALL_DEVICE}" rm "${PARTITION_NUMBER}"
	done
	
	# sync the system partition tables
	disk_sync
	# create initial gpt structures
	parted -s "${INSTALL_DEVICE}" mklabel gpt
}

create_partitions(){
	
	# create a 25MB "EFI" partition (starting at sector 40 is important)
	# create partition and format
	parted -s "${INSTALL_DEVICE}" mkpart primary fat32 40s 69671s || exit
	disk_sync
	parted -s "${INSTALL_DEVICE}" set "${CURRENT_PARTITION_NUMBER}" boot on
	mkfs.msdos -F 32 -n EFI "${INSTALL_DEVICE}${PARTITION_PREFIX}1" &>/dev/null || exit
	CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	

	# create a "Recovery" partition
	RECOVERY_PARTITION_NUMBER=${CURRENT_PARTITION_NUMBER}
	get_partition_end "$(( ${CURRENT_PARTITION_NUMBER} - 1 ))"
	START="${PARTITION_END}"
	if [ -z "${RECOVERY_MIN}" ];then
		RECOVERY_MIN=150
	fi
	# validate control file data
	if [ -n "${RECOVERY_SIZE}" ];then
		RECOVERY_NUMBER=$(echo ${RECOVERY_SIZE} | tr -dc 0-9)
		if [ -z "${RECOVERY_NUMBER}" ];then
			RECOVERY_NUMBER=0
		fi
		if [ "${RECOVERY_SIZE}" == "auto" -o ${RECOVERY_NUMBER} -lt ${RECOVERY_MIN} ];then
			RECOVERY_SIZE=${RECOVERY_MIN}
		elif [ ${RECOVERY_NUMBER} -gt ${RECOVERY_MIN} ];then
			RECOVERY_SIZE=${RECOVERY_NUMBER}
		fi
	fi

	if [ -z "${RECOVERY_SIZE}" -a "${AUTOMATED_INSTALL}" == "true" ];then
		RECOVERY_SIZE=${RECOVERY_MIN}
	fi
	while [ -z "${RECOVERY_SIZE}" ];do
		echo ""
		read_input "Please specify desired flash partition size (in MB, ${RECOVERY_MIN} recommended): "
		strip_alpha_characters "${INPUT}"
		RECOVERY_SIZE="${STRIPPED}"
		if [ ${RECOVERY_SIZE} -lt ${RECOVERY_MIN} ];then
			RECOVERY_SIZE=""
		fi
	done
	RECOVERY_END=$(echo "${START} ${RECOVERY_SIZE}" | awk '{printf($1 + $2)}')

	# create partition and format
	parted -s "${INSTALL_DEVICE}" mkpart primary HFS "${START}MB" "${RECOVERY_END}MB" || exit
	parted -s "${INSTALL_DEVICE}" set "${RECOVERY_PARTITION_NUMBER}" atvrecv on
	disk_sync
	RECOVERY_RANDOM=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
	#echo "RANDOM: ${RANDOMFOO}"
	RECOVERY_LABEL="Recovery${RECOVERY_RANDOM}"
	mkfs.hfsplus -s -v "${RECOVERY_LABEL}" "${INSTALL_DEVICE}${PARTITION_PREFIX}${RECOVERY_PARTITION_NUMBER}"
	fsck.hfsplus "${INSTALL_DEVICE}${PARTITION_PREFIX}${RECOVERY_PARTITION_NUMBER}" > /dev/null
	RECOVERY_MNT_DIR=$(mktemp -d "/tmp/mounts.XXXXXX")
	mount "${INSTALL_DEVICE}${PARTITION_PREFIX}${RECOVERY_PARTITION_NUMBER}" "${RECOVERY_MNT_DIR}"

	CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	
}

extract_fresh_recovery(){
	TMP=$(mktemp -d "/tmp/recovery.XXXXXX")
	tar -zxvf "${THIRDPARTY_DIR}/recovery/recovery-1.0.tar.gz" -C "${TMP}" > /dev/null || exit
	RECOVERY_TMP_DIR="${TMP}"
}

install_vanilla_recovery(){
	# copy atv-bootloader over
	extract_fresh_recovery
	cp -arp "${RECOVERY_TMP_DIR}/recovery/"* "${RECOVERY_MNT_DIR}" > /dev/null || exit
	rm -rf "${RECOVERY_TMP_DIR}"
	disk_sync
}

install_elec(){
	
	# create "Storage" partition
	get_partition_end "$(( ${CURRENT_PARTITION_NUMBER} - 1 ))"
	STORAGE_PARTITION_NUMBER=$CURRENT_PARTITION_NUMBER
	STORAGE_START="${PARTITION_END}"
	DRIVE_END=$(parted -s "${INSTALL_DEVICE}" print -m | egrep "^${INSTALL_DEVICE}" | cut -d : -f 2)
	STORAGE_MIN=150

	if [ -n "${STORAGE_END}" ];then
		STORAGE_NUMBER=$(echo ${STORAGE_END} | tr -dc 0-9)
		if [ -z "${STORAGE_NUMBER}" ];then
			STORAGE_NUMBER=0
		fi
		if [ "${STORAGE_END}" == "auto" -o ${STORAGE_NUMBER} -lt ${STORAGE_MIN} ];then
			STORAGE_END=${DRIVE_END}
		elif [ ${STORAGE_NUMBER} -gt ${STORAGE_MIN} ];then
			STORAGE_END=${STORAGE_NUMBER}
		fi
	fi

	if [ -z "${STORAGE_END}" -a "${AUTOMATED_INSTALL}" == "true" ];then
		STORAGE_END=${DRIVE_END}
	fi

	while [ -z "${STORAGE_END}" ];do
		echo ""
		read_input "Please specify desired END position of storage partition (recommended ${DRIVE_END}): "
		STORAGE_END="${INPUT}"
	done
	
	# create storage partiion and format it
	parted -s "${INSTALL_DEVICE}" mkpart primary ext3 "${STORAGE_START}MB" "${STORAGE_END}MB" || exit
	disk_sync
	mkfs.ext3 -L "storage" "${INSTALL_DEVICE}${PARTITION_PREFIX}${STORAGE_PARTITION_NUMBER}"
	fsck.ext3 "${INSTALL_DEVICE}${PARTITION_PREFIX}${STORAGE_PARTITION_NUMBER}"
	STORAGE_UUID=$(blkid -o value -s UUID "${INSTALL_DEVICE}${PARTITION_PREFIX}${STORAGE_PARTITION_NUMBER}")
	STORAGE_MNT_DIR=$(mktemp -d "/tmp/mounts.XXXXXX")
	mount "${INSTALL_DEVICE}${PARTITION_PREFIX}${STORAGE_PARTITION_NUMBER}" "${STORAGE_MNT_DIR}"
	CURRENT_PARTITION_NUMBER=$(( ${CURRENT_PARTITION_NUMBER} + 1 ))
	
	cp -arp "${TARGET_DIR}/"* "${RECOVERY_MNT_DIR}"
}

setup_elec_recovery(){
	# com.apple.Boot.plist.elec
	ELEC_PLIST="${RECOVERY_MNT_DIR}/com.apple.Boot.plist.elec"
	SED_BOOT_DEVICE=$(echo "${BOOT_DEVICE}" | sed 's/\//\\\//g')
	sed -i "s/%bootlogo%/${BOOTLOGO_FILENAME}/g" "${ELEC_PLIST}"
	sed -i "s/%boot_string%/LABEL=${RECOVERY_LABEL}/g" "${ELEC_PLIST}"
	sed -i "s/%disk_string%/UUID=${STORAGE_UUID}/g" "${ELEC_PLIST}"
	
	sed -i "s/%extra_kernel_flags%/${EXTRA_KERNEL_FLAGS}/" "${ELEC_PLIST}"

	mv "${RECOVERY_MNT_DIR}/com.apple.Boot.plist" "${RECOVERY_MNT_DIR}/com.apple.Boot.plist.recovery"
	mv "${RECOVERY_MNT_DIR}/mach_kernel" "${RECOVERY_MNT_DIR}/mach_kernel.recovery"

	cd "${RECOVERY_MNT_DIR}"
	#cp "./KERNEL" "./mach_kernel.elec"
	cp "./com.apple.Boot.plist.elec" "./com.apple.Boot.plist"
	
	#ln -sf "./KERNEL" "./mach_kernel.elec"
	#ln -sf "./com.apple.Boot.plist.elec" "./com.apple.Boot.plist"
	cd "${START_PWD}"
}

final_cleanup(){
	echo ""
	echo "Congrats!  You are almost finished"
	echo "We just have a few more items to clean up"
	echo "Please be patient as this may take some time..."
	chown -R root:root "${RECOVERY_MNT_DIR}"
	disk_sync
	unmount_install_device_partitions
	echo ""
	echo "Phew! ALL DONE!  That wasn't very difficult was it?"
	echo "It's now safe to remove your device and connect it to the ATV"
	echo ""
}

main(){
	
	if [ $UID != 0 ];then
		echo "you *must* run this as root"
		usage
		exit 1
	fi

	if [ -f "${SCRIPT_DIR}/control" ];then
		source "${SCRIPT_DIR}/control"
	fi
	
	if [ -f "${CLI_CONTROL_FILE}" ];then
		echo "sourcing cli file"
		source "${CLI_CONTROL_FILE}"
	fi

	if [ -z "${INSTALL_DEVICE}" ];then
		ask_for_install_device
	fi

	if [ "${AUTOMATED_INSTALL}" != "true" ];then
		validate_install_device
	fi
	
	unmount_install_device_partitions

	if [ $(echo "${INSTALL_DEVICE}" | grep "loop") ];then
		IS_LOOP="true"
	else
		IS_LOOP="false"
	fi

	if [ "${IS_LOOP}" == "true" ];then
		PARTITION_PREFIX="p"
	else
		PARTITION_PREFIX=""
	fi

	prepare_install_device
	create_partitions
	install_vanilla_recovery
	echo ""
	echo "Recovery image created successfully!"
	echo ""

	if [ -z "${INSTALL_ELEC}" ];then
		if [ "${AUTOMATED_INSTALL}" != "true" ];then
			yes_no "Would you like to also install OpenElec.tv? " "Y"
			if [ $? -eq 0 ];then
				INSTALL_ELEC="true"
			else
				INSTALL_ELEC="false"
			fi
		else
			INSTALL_ELEC="true"
		fi
	fi
	
	if [ "${INSTALL_ELEC}" == "true" ];then
		install_elec
		setup_elec_recovery
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
			-c | --control )		shift
									CLI_CONTROL_FILE=$1
									echo $CLI_CONTROL_FILE
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

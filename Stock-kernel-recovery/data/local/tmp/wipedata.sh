#!/system/bin/sh
# @(#) Recovery for Xperia SP ver. 4.4.1 2014.07.09
# Description:
#   A wipedata script that simple function with logging based on
#      chargemon for Xperia T/TX/TL/V ver. 2.2.0 2013.04.13 script.
# Original author:
#   cray_Doze
# Ported to Xperia SP By:
#   dssmex
###########################################################################

# Functions
# Command setup
CMD_SETUP(){
	DATE="${BUSYBOX} date"
	MKDIR="${BUSYBOX} mkdir"
	CHOWN="${BUSYBOX} chown"
	CHMOD="${BUSYBOX} chmod"
	MV="${BUSYBOX} mv"
	TOUCH="${BUSYBOX} touch"
	CAT="${BUSYBOX} cat"
	SLEEP="${BUSYBOX} sleep"
	KILL="${BUSYBOX} kill"
	RM="${BUSYBOX} rm"
	PS="${BUSYBOX} ps"
	GREP="${BUSYBOX} grep"
	AWK="${BUSYBOX} awk"
	EXPR="${BUSYBOX} expr"
	MOUNT="${BUSYBOX} mount"
	UMOUNT="${BUSYBOX} umount"
	TAR="${BUSYBOX} tar"
	GZIP="${BUSYBOX} gzip"
	CPIO="${BUSYBOX} cpio"
	CHROOT="${BUSYBOX} chroot"
	LS="${BUSYBOX} ls"
	HEXDUMP="${BUSYBOX} hexdump"
	CP="${BUSYBOX} cp"
}

# Function definition for logging
ECHOL(){
	_DATETIME=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S-%Z"`
	echo "${_DATETIME}: $*" >> ${LOGFILE}
	return 0
}

# function definition for log exec command
EXECL(){
	_DATETIME=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S-%Z"`
	echo "${_DATETIME}: $*" >> ${LOGFILE}
	$* 2>> ${LOGFILE}
	_RET=$?
	echo "${_DATETIME}: RET=${_RET}" >> ${LOGFILE}
	return ${_RET}
}

#Function definition for get property
GETPROP(){
	# Get the property from getprop
	PROP=`/system/bin/getprop $*`
	PROP=`grep "$*" /system/build.prop | awk -F'=' '{ print $NF }'`
	echo $PROP
}
	
# function umount 
UMOUNT_ALL(){
	# umount
	${UMOUNT} -l /dev/block/mmcblk0p6  # /boot/modem_fs1
	${UMOUNT} -l /dev/block/mmcblk0p7  # /boot/modem_fs2
	${UMOUNT} -l /dev/block/mmcblk0p13 # /system
	${UMOUNT} -l /dev/block/mmcblk0p15 # /data
	${UMOUNT} -l /dev/block/mmcblk0p10 # /mnt/idd
	${UMOUNT} -l /dev/block/mmcblk0p14 # /cache
	${UMOUNT} -l /dev/block/mmcblk0p12 # /lta-label
	${UMOUNT} -l /dev/block/mmcblk1p1  # /sdcard (External)
	${BUSYBOX} sync

	${UMOUNT} /system
	${UMOUNT} /data
	${UMOUNT} /mnt/idd
	${UMOUNT} /cache
	${UMOUNT} /lta-label

	## SDcard
	# Internal SDcard umountpoint
	${UMOUNT} /sdcard
	${UMOUNT} /mnt/sdcard
	${UMOUNT} /storage/sdcard0

	# External SDcard umountpoint
	${UMOUNT} /sdcard1
	${UMOUNT} /ext_card
	${UMOUNT} /storage/sdcard1

	# External USB umountpoint
	${UMOUNT} /mnt/usbdisk
	${UMOUNT} /usbdisk
	${UMOUNT} /storage/usbdisk

    # legacy folders
	${UMOUNT} /storage/emulated/legacy/Android/obb
	${UMOUNT} /storage/emulated/legacy
	${UMOUNT} /storage/emulated/0/Android/obb
	${UMOUNT} /storage/emulated/0
	${UMOUNT} /storage/emulated
	${UMOUNT} /storage/removable/sdcard1
	${UMOUNT} /storage/removable/usbdisk
	${UMOUNT} /storage/removable
	${UMOUNT} /storage
	${UMOUNT} /mnt/shell/emulated/0
	${UMOUNT} /mnt/shell/emulated
	${UMOUNT} /mnt/shell

	## misc
	${UMOUNT} /mnt/obb
	${UMOUNT} /mnt/asec
	${UMOUNT} /mnt/secure/staging
	${UMOUNT} /mnt/secure
	${UMOUNT} /mnt
	${UMOUNT} /acct
	${UMOUNT} /dev/cpuctl
	${UMOUNT} /dev/pts
	${UMOUNT} /sys/fs/selinux
	${UMOUNT} /sys/kernel/debug
	${BUSYBOX} sync
}

# Disable glove mode
DISABLE_GLOVEMODE() {
	# Disabling Glove Mode
	ECHOL "### Disable glove mode..."
	echo "280" > /sys/devices/i2c-3/3-0024/main_ttsp_core.cyttsp4_i2c_adapter/finger_threshold
	echo "0" > /sys/devices/i2c-3/3-0024/main_ttsp_core.cyttsp4_i2c_adapter/signal_disparity  
}

# Enable glove mode
ENABLE_GLOVEMODE() {
	# enabling Glove Mode
	ECHOL "### Disable glove mode..."
	echo "280" > /sys/devices/i2c-3/3-0024/main_ttsp_core.cyttsp4_i2c_adapter/finger_threshold
	echo "136" > /sys/devices/i2c-3/3-0024/main_ttsp_core.cyttsp4_i2c_adapter/signal_disparity  
}

# add init.d support at boot
ADD_INITD() {
	#add init.d runparts if not added
	if [ `${GREP} -c "run-parts /system/etc/init.d" /system/etc/init.qcom.post_boot.sh` == 0 ];then
		ECHOL " "
		ECHOL "### No init.d support detected, adding init.d support in /system/etc/init.qcom.post_boot.sh"
		ECHOL "### remounting system as rw..."
		EXECL ${MOUNT} -o remount,rw /system
		echo " " >> /system/etc/init.qcom.post_boot.sh
		echo "# dssmex: init.d support" >> /system/etc/init.qcom.post_boot.sh
		echo " /system/bin/logwrapper busybox run-parts /system/etc/init.d" >> /system/etc/init.qcom.post_boot.sh
		echo " " >> /system/etc/init.qcom.post_boot.sh
		ECHOL "### remounting system as ro..."
		EXECL ${MOUNT} -o remount,ro /system
	fi
	
	#add init.d directory if not exists
	if [ ! -d /system/etc/init.d ];then
		EXECL ${MOUNT} -o remount,rw /system
		EXECL ${MKDIR} /system/etc/init.d
		EXECL ${CHOWN} root.root /system/etc/init.d
		EXECL ${CHMOD} 751 /system/etc/init.d
		EXECL ${MOUNT} -o remount,ro /system
	fi
}

# start routines
# prevent reload's
if [ ! -e /wipedata.log ]; then
	set +x
    # Backup PATH
	OLDPATH="$PATH"
	# Environment variable definition
	export PATH="/sbin:/system/xbin:/system/bin"

	# Constant definition
	LOGPATH="/cache/wipedata"
	LOGFILE="${LOGPATH}/wipedata.log"
	WORKDIR="${LOGPATH}"
	BTMGRPATH="/system/btmgr"

	# Busybox setup
	if [ -x "${BTMGRPATH}/bin/busybox" ]; then
		BUSYBOX="${BTMGRPATH}/bin/busybox"
	elif [ -x "/system/xbin/busybox" ]; then
		BUSYBOX="/system/xbin/busybox"
	elif [ -x "/system/bin/busybox" ]; then
		BUSYBOX="/system/bin/busybox"
	else
		BUSYBOX=""
	fi
	# setup Commands
	CMD_SETUP

	# add temp log file
	_DT=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S"`
	${MOUNT} -o remount,rw rootfs /	
	echo "${_DT} - wipedata loaded" >> /wipedata.log
	${MOUNT} -o remount,ro rootfs /	

	# Logfile rotation
	if [ ! -d "${LOGPATH}" ];then
		${MKDIR} ${LOGPATH}
		${CHOWN} system.cache ${LOGPATH}
		${CHMOD} 770 ${LOGPATH}
	else
		if [ -f ${LOGFILE} ];then
			${MV} ${LOGFILE} ${LOGFILE}.old
		fi
		${TOUCH} ${LOGFILE}
		${CHMOD} 660 ${LOGFILE}
	fi

	# Initialize system clock.
	ECHOL " "
	ECHOL "### set timezone..."
	EXECL export TZ "$(getprop persist.sys.timezone)"

	#fix time daemon library path
	OLD_LD="$LD_LIBRARY_PATH"
	EXECL export LD_LIBRARY_PATH=/system/vendor:/system/lib
	
	#start time daemon
	ECHOL "###   start time_daemon..."
	EXECL /system/bin/time_daemon &

	# need this three lines
	ECHOL "###  "
	ECHOL "###   wait 3 secs..."
	EXECL ${SLEEP} 3
  
	### kill time_daemon...
	ECHOL "###   kill time_daemon..."
	EXECL kill -9 $(ps | grep time_daemon | grep -v grep | awk -F' ' '{print $1}')	

	# Restore Library path
	EXECL export LD_LIBRARY_PATH=${OLD_LD}

	# Start main routine
	ECHOL " "
	ECHOL "############################################"
	ECHOL "### wipedata hijack start...              ##"
	ECHOL "############################################"
	ECHOL " "
	ECHOL "### BUSYBOX=${BUSYBOX}"

	# Make work directory
	ECHOL "### check workdir..."
	if [ ! -d "${WORKDIR}" ];then
		EXECL ${MKDIR} ${WORKDIR}
		EXECL ${CHOWN} system.cache ${WORKDIR}
		EXECL ${CHMOD} 770 ${WORKDIR}
	fi

	# Clear work directory
	ECHOL "### clean workdir..."
	if [ ! -e ${WORKDIR}/keycheck ];then
		EXECL ${RM} ${WORKDIR}/keyevent*
		EXECL ${RM} ${WORKDIR}/keycheck_camera
		EXECL ${RM} ${WORKDIR}/keycheck_up
		EXECL ${RM} ${WORKDIR}/keycheck_down
	fi

	# LED settings for Xperia SP
	LEDC1_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_R/led_current)"
	LEDC1_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_B/led_current)"
	LEDC1_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_G/led_current)"
	LEDB1_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_R/brightness)"
	LEDB1_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_B/brightness)"
	LEDB1_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED1_G/brightness)"

	LEDC2_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_R/led_current)"
	LEDC2_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_B/led_current)"
	LEDC2_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_G/led_current)"
	LEDB2_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_R/brightness)"
	LEDB2_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_B/brightness)"
	LEDB2_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED2_G/brightness)"

	LEDC3_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_R/led_current)"
	LEDC3_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_B/led_current)"
	LEDC3_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_G/led_current)"
	LEDB3_RED="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_R/brightness)"
	LEDB3_BLUE="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_B/brightness)"
	LEDB3_GREEN="$(${LS} /sys/devices/i2c-10/10-0047/leds/LED3_G/brightness)"

	# check recovery flag
    RECOVERY_FLAG=false
	if [ -e /cache/recovery/boot ] || ${GREP} -q warmboot=0x77665502 /proc/cmdline || ${GREP} -q warmboot=0x6F656D01 /proc/cmdline || ${GREP} -q warmboot=0x6F656D02 /proc/cmdline || ${GREP} -q warmboot=0x6F656D03 /proc/cmdline; then
		ECHOL "### found reboot into recovery flag..." 		
		RECOVERY_FLAG=true
	else
		# keycheck for recovery-boot
		ECHOL "### keycheck..."

		# Turn on GREEN-led.
		echo "128" > ${LEDC3_GREEN}
		echo "128" > ${LEDB3_GREEN}
		${SLEEP} 0.4
		# Turn on white-led.
		echo "128" > ${LEDC1_RED}
		echo "128" > ${LEDC1_BLUE}
		echo "128" > ${LEDC1_GREEN}
		echo "64" > ${LEDB1_RED}
		echo "128" > ${LEDB1_BLUE}
		echo "128" > ${LEDB1_GREEN}
		${SLEEP} 0.4
		# Turn on red-led.
		echo "128" > ${LEDC2_RED}
		echo "128" > ${LEDB2_RED}
		${SLEEP} 0.4

		# Turn off GREEN-led.
		echo "0" > ${LEDC3_GREEN}
		# Turn off white-led.
		echo "0" > ${LEDC1_RED}
		echo "0" > ${LEDC1_BLUE}
		echo "0" > ${LEDC1_GREEN}
		# Turn off RED-led.
		echo "0" > ${LEDC2_RED}
  
		# Turn on blue-led.
		echo "128" > ${LEDC2_BLUE}
		echo "128" > ${LEDB2_BLUE}
  
		# trigger vibration
		echo '200' > /sys/class/timed_output/vibrator/enable

		for EVENTDEV in $(${LS} /dev/input/event* )
		do
			SUFFIX="$(${EXPR} ${EVENTDEV} : '/dev/input/event\(.*\)')"
			${CAT} ${EVENTDEV} > ${WORKDIR}/keyevent${SUFFIX} &
		done
		${SLEEP} 3

		${PS} > ${LOGPATH}/ps.log
		${CHMOD} 660 ${LOGPATH}/ps.log

		for CATPROC in $(${PS} | ${GREP} /dev/input/event | ${GREP} -v grep | ${AWK} '{print $1}')
		do
			EXECL ${KILL} -9 ${CATPROC}
		done

		# Turn off blue-led.
		echo "0" > ${LEDC2_BLUE}

		#vol up
		${HEXDUMP} ${WORKDIR}/keyevent* | ${GREP} -e '^.* 0001 0073 .... ....$' > ${WORKDIR}/keycheck_up
		#vol down
		${HEXDUMP} ${WORKDIR}/keyevent* | ${GREP} -e '^.* 0001 0072 .... ....$' > ${WORKDIR}/keycheck_down
		#camera
		${HEXDUMP} ${WORKDIR}/keyevent* | ${GREP} -e '^.* 0001 0210 .... ....$' > ${WORKDIR}/keycheck_camera
	fi

	## select ramdisk
	RAMDISK=""

	# Philz Touch (vol up)
	if [ -s ${WORKDIR}/keycheck_up -a -n "${BUSYBOX}" ];then
		ECHOL "### Select Philz Touch recovery boot mode..."
		RAMDISK="philz.cpio"
		DISABLE_GLOVEMODE
	fi

	# TWRP (Vol down)
	if [ -s ${WORKDIR}/keycheck_down -a -n "${BUSYBOX}" ];then
		ECHOL "### Select TWRP recovery boot mode..."
		RAMDISK="twrp.cpio"
		DISABLE_GLOVEMODE
	fi

	# CWM Touch(camera button) or reboot in recovery mode 
	if [ -s ${WORKDIR}/keycheck_camera -a -n "${BUSYBOX}" ] || ${RECOVERY_FLAG};then
		ECHOL "### Select CWM-Touch recovery boot mode..."
		RAMDISK="cwm.cpio"
		DISABLE_GLOVEMODE
	fi
	
	# if not press any key run enhanced stock ramdisk
	if [ "${RAMDISK}" == "" ];then
		ECHOL "### Select Enhanced boot mode..."
		RAMDISK="ramdisk.cpio"
	fi
 
	# Boot custom selected if exists
	EXECL cd /
	if [ -f ${BTMGRPATH}/${RAMDISK}.gz ];then
		ECHOL "### ${RAMDISK} exists..."
	
		# removing flag to enter recovery
		if [ -f /cache/recovery/boot ]; then
			EXECL ${RM} /cache/recovery/boot
		fi

		# don´t blik green light in enhanced ramdisk
		if [ ! "${RAMDISK}" == "ramdisk.cpio" ];then
			# Recovery boot mode notification
			echo "128" > ${LEDC2_GREEN}
			echo "128" > ${LEDB2_GREEN}
			${SLEEP} 1
			echo "0" > ${LEDC2_GREEN}
		fi

		ECHOL "### Checking device model..."
		MODEL=$(GETPROP ro.product.model)
		VERSION=$(GETPROP ro.build.id)
		PHNAME=$(GETPROP ro.semc.product.name)
		EVENTNODE=$(GETPROP dr.gpiokeys.node)
		ECHOL "Model found: $MODEL ($PHNAME - $VERSION)"
	
		# remount rootfs to rw.
		ECHOL "### remount rootfs to rw..."
		EXECL ${MOUNT} -o remount,rw rootfs /	
	
		# Install exfat module to support exfat file system
		ECHOL "### Install exfat module..."
		EXECL insmod /system/lib/modules/texfat.ko	
	
		# Stop init services.
		ECHOL "### stop init services..."
		for SVCRUNNING in $(getprop | ${GREP} -E '^\[init\.svc\..*\]: \[running\]' | ${GREP} -v ueventd)
		do
			SVCNAME=$(${EXPR} ${SVCRUNNING} : '\[init\.svc\.\(.*\)\]:.*')
			EXECL stop ${SVCNAME}
		done
	
		# Kill remaining processes under /system/bin
		ECHOL "### Kill remaining process..."
		for RUNNINGPRC in $(${PS} | ${GREP} /system/bin | ${GREP} -v grep | ${GREP} -v wipedata | ${AWK} '{print $1}' )
		do
			EXECL ${KILL} -9 ${RUNNINGPRC}
		done

		# Kill remaining processes under /sbin
		for RUNNINGPRC in $(ps | grep /sbin | grep -v grep | awk '{print $1}' )
		do
			EXECL ${KILL} -9 ${RUNNINGPRC}
		done
				
		## Moving Busybox to /res
		ECHOL "### moving busybox.."
		EXECL ${RM} -rf /res
		EXECL ${MKDIR} mkdir /res 
		EXECL ${CHOWN} 0.0 /res
		EXECL ${CHMOD} 0777 /res
		EXECL ${CP} ${BUSYBOX} /res		
		BUSYBOX="/res/busybox"
		# Setup busybox commands again 
		CMD_SETUP
		
		## Move and decompress ramdisk to /res
		ECHOL "### moving ${RAMDISK}.gz..."
		EXECL ${CP} ${BTMGRPATH}/${RAMDISK}.gz /res
		ECHOL "### decompress ${RAMDISK}.gz..."
		EXECL ${GZIP} -d /res/${RAMDISK}.gz

		## cleaninig
		# umount partitions, stripping the ramdisk to bare metal
		ECHOL " ### Umount partitions and then executing init..."
		EXECL ${UMOUNT} -l /acct
		EXECL ${UMOUNT} -l /dev/cpuctl
		EXECL ${UMOUNT} -l /dev/pts
		EXECL ${UMOUNT} -l /mnt/asec
		EXECL ${UMOUNT} -l /mnt/obb
		EXECL ${UMOUNT} -l /mnt/secure	 
		EXECL ${UMOUNT} -l /mnt/idd		# Appslog
		EXECL ${UMOUNT} -l /data		# Userdata
		
		# AS OF HERE NO MORE BUSYBOX SYMLINKS IN $PATH!!!!
		ECHOL "### umounting system  ..."
		EXECL ${UMOUNT} -l /system 
		export PATH="/sbin"

		# rm symlinks & files.
		ECHOL "### Remove symlinks and files in rootfs"
		EXECL ${BUSYBOX} find . -maxdepth 1 \( -type l -o -type f \) -exec ${RM} -fv {} \; 2>&1 

		# Remove some directories
		ECHOL "### Remove directories..."
		for directory in `${BUSYBOX} find . -maxdepth 1 -type d`; do
			if [ "$directory" != "." -a "$directory" != ".." -a "$directory" != "./" -a "$directory" != "./dev" -a "$directory" != "./proc" -a "$directory" != "./sys" -a "$directory" != "./res" -a "$directory" != "./cache" ]; then
				EXECL ${BUSYBOX} echo "rm -vrf $directory" 
				EXECL ${RM} -vrf $directory 2>&1 
			fi
		done	

		# log in /wipelata.log
		_DT=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S"`
		echo "${_DT} - ${RAMDISK} loaded\n" >> /wipedata.log
		
		# log process before extract ramdisk in /wipelata.log
		echo "\n\n ***** process before extract ramdisk ***** \n" >> /wipedata.log
		${PS} >> /wipedata.log
		echo "\n\n ***** directory before extract ramdisk ***** \n" >> /wipedata.log
		${LS} -la >> /wipedata.log
		
		# extract recovery
		ECHOL "### Extracting ramdisk.."
		EXECL ${CPIO} -i < /res/${RAMDISK}
		
		# From here on, the log dies, as these are the locations we log to!
		# Ending log
		DATETIME=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S"`
		ECHOL "STOP wipedata at ${DATETIME}: Executing recovery init!" 

		# log final process in /wipelata.log
		echo "\n\n ***** process before exec init ***** \n" >> /wipedata.log
		${PS} >> /wipedata.log

		${UMOUNT} -l /storage/sdcard1	# SDCard1
		${UMOUNT} -l /cache				# Cache
		${UMOUNT} -l /proc
		${UMOUNT} -l /sys

		# setting for enhanced ramdisk
		if [ "${RAMDISK}" == "ramdisk.cpio" ];then
					
			# Restore original path
			export PATH=${OLDPATH}	
			
			# umount all remaining 
			UMOUNT_ALL
		fi

		echo "\n\n ***** directory before exec init ***** \n" >> /wipedata.log
		${LS} -la >> /wipedata.log
		
		# wait 
		${SLEEP} 2        

		# run 
		exec /init
	
		# reboot when an error occurs
		reboot
	else
		ECHOL "### ${RAMDISK} not found..."
		ENABLE_GLOVEMODE
	fi

	#init.d support if don't use enhanced ramdisk 
	ADD_INITD

	ECHOL " "
	ECHOL "### go to normal boot mode..."

	# Restore path
	export PATH=${OLDPATH}
fi 

# Continue booting in case of failure
exec /system/bin/wipedata.stock
exit 0

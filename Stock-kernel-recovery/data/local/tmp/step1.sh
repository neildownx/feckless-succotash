#!/system/bin/sh
# Recoveries installer 
# supported by dssmex 
# Last modification 2014/jul/09			
#######################################

#######################################
# Functions
#######################################
# Function to clean temp files
CLEANFILES() {
	# cleaning temp files
	echo " "
	echo "------- Cleaning files ------"
	busybox rm -f /data/local/tmp/wipedata.sh
	busybox rm -f /data/local/tmp/chargemon.sh
	busybox rm -f /data/local/tmp/ramdisk.cpio.gz
	busybox rm -f /data/local/tmp/philz.cpio.gz
	busybox rm -f /data/local/tmp/cwm.cpio.gz
	busybox rm -f /data/local/tmp/twrp.cpio.gz
	busybox rm -f /data/local/tmp/busybox
	busybox rm -f /data/local/tmp/ric
}

# function to detect the device and version installed
DETECT_DEVICE(){
	# init vars
	VERSION="Unknown"
	PRODUCT="Unknown"
	
	# detecting product number
	if [ `cat /system/build.prop | grep "ro.product.name" | grep -c "C5302"` = 1 ];then
    	PRODUCT="C5302"
		IS_C5302=true
	else
		IS_C5302=false
	fi
	if [ `cat /system/build.prop | grep "ro.product.name" | grep -c "C5303"` = 1 ];then
    	PRODUCT="C5303"
		IS_C5303=true
	else
		IS_C5303=false
	fi
	if [ `cat /system/build.prop | grep "ro.product.name" | grep -c "C5306"` = 1 ];then
    	PRODUCT="C5306"
		IS_C5306=true
	else
		IS_C5306=false
	fi
	
    # detecting version number
	if [ `cat /system/build.prop | grep "ro.build.version.release" | grep -c "4.4.4"` = 1 ];then
		VERSION="4.4.4" 
		IS_CM11=true
	else
		IS_CM11=false
	fi
	if [ `cat /system/build.prop | grep "ro.build.version.release" | grep -c "4.3"` = 1 ];then
		VERSION="4.3" 
		IS_JB43=true
	else
		IS_JB43=false
	fi
	if [ `cat /system/build.prop | grep "ro.build.version.release" | grep -c "4.1.2"` = 1 ];then
		VERSION="4.1.2" 
		IS_JB41=true
	else
		IS_JB41=false
	fi
}
#######################################

#######################################
# Main script
#######################################
echo ""
echo "--- mounting system as rw ---"

# remounting system as read and write
chmod 755 /data/local/tmp/busybox
/data/local/tmp/busybox mount -o remount, rw /system

echo ""
echo "--- installing busybox ------"
echo ""

# add recovery dirs
if [ ! -d /system/btmgr ]; then
  echo "adding /system/btmgr dir..."
  mkdir /system/btmgr
fi
if [ ! -d /system/btmgr/bin ]; then
  echo "adding /system/btmgr/bin dir..."
  mkdir /system/btmgr/bin
fi

# adding custom busybox v1.21.1
echo "copying files..."
dd if=/data/local/tmp/busybox of=/system/btmgr/bin/busybox
chown root.shell /system/btmgr/bin/busybox
chmod 755 /system/btmgr/bin/busybox
dd if=/data/local/tmp/busybox of=/system/xbin/busybox
chown root.shell /system/xbin/busybox
chmod 755 /system/xbin/busybox
echo ""
echo "installing..."
/system/xbin/busybox --install -s /system/xbin
echo "                  [OK]"

# detect Device and version
echo ""
echo "-- Getting model and version number --"
echo ""
DETECT_DEVICE

if  ${IS_C5302} || ${IS_C5303} || ${IS_C5306};then
	echo "Model Number: ${PRODUCT}"
else
	echo "Model Number: ${PRODUCT}  --> (ERROR: NOT COMPATIBLE) :("
	CLEANFILES
	exit 2
fi
if ${IS_CM11} || ${IS_JB43} || ${IS_JB41};then
	echo "Version     : ${VERSION}"
else
	echo "Version     : ${VERSION}  --> (ERROR: NOT COMPATIBLE) :("
	CLEANFILES
	exit 3
fi
echo "Model and version number supported! :)"

#kill ric process
echo ""
echo "----- Killing ric process ------"
pkill -f /system/bin/ric 
pkill -f /sbin/ric 

# backup stock ric
if [ ! -f /system/bin/ric.stock ]; then
    echo ""
	echo "Backing up ric..."
	mv /system/bin/ric /system/bin/ric.stock
fi

# add hijacked ric
echo ""
echo "adding hijacked ric..."
dd if=/data/local/tmp/ric of=/system/bin/ric
chmod 755 /system/bin/ric

echo ""
echo "---- installing recoveries ----"

# wipe old ramdisk's
# ramdisk.cpio
if [ -f /system/bin/ramdisk.cpio ]; then
	rm /system/bin/ramdisk.cpio
    echo ""
	echo "old ramdisk removed..."
fi
if [ -f /system/btmgr/ramdisk.cpio.gz ]; then
	rm /system/btmgr/ramdisk.cpio.gz
    echo ""
	echo "old ramdisk removed..."
fi

# philz.cpio
if [ -f /system/bin/philz.cpio ]; then
	rm /system/bin/philz.cpio
    echo ""
	echo "old philz ramdisk removed..."
fi

# twrp.cpio
if [ -f /system/bin/twrp.cpio ]; then
	rm /system/bin/twrp.cpio
    echo ""
	echo "old twrp ramdisk removed..."
fi

# cwm.cpio
if [ -f /system/bin/cwm.cpio ]; then
	rm /system/bin/cwm.cpio
    echo ""
	echo "old cwm ramdisk removed..."
fi

# adding ramdisk's
if ${IS_CM11};then
	# adding Cyanogenmod ramdisk 
    echo ""
	echo "adding CM11 Ramdisk..."
	dd if=/data/local/tmp/ramdisk.cpio.gz of=/system/btmgr/ramdisk.cpio.gz
	chown root.shell /system/btmgr/ramdisk.cpio.gz
	chmod 644 /system/btmgr/ramdisk.cpio.gz
fi

# adding Philz Touch
echo ""
echo "adding Philz Touch Ramdisk..."
dd if=/data/local/tmp/philz.cpio.gz of=/system/btmgr/philz.cpio.gz
chown root.shell /system/btmgr/philz.cpio.gz
chmod 644 /system/btmgr/philz.cpio.gz

# adding TWRP
echo ""
echo "adding TWRP Ramdisk..."
dd if=/data/local/tmp/twrp.cpio.gz of=/system/btmgr/twrp.cpio.gz
chown root.shell /system/btmgr/twrp.cpio.gz
chmod 644 /system/btmgr/twrp.cpio.gz

# adding CWM Touch
echo ""
echo "adding CWM Touch Ramdisk..."
dd if=/data/local/tmp/cwm.cpio.gz of=/system/btmgr/cwm.cpio.gz
chown root.shell /system/btmgr/cwm.cpio.gz
chmod 644 /system/btmgr/cwm.cpio.gz

if ${IS_JB41};then
	# JB 4.1.2
	# Backup stock chargemon
	if [ ! -f /system/bin/chargemon.stock ]; then
		echo ""
		echo "backing up stock chargemon..."
		dd if=/system/bin/chargemon of=/system/bin/chargemon.stock
	fi
	# correcting permissions
	chown root.shell /system/bin/chargemon.stock
	chmod 755 /system/bin/chargemon.stock

	# adding hacked chargemon
	echo ""
	echo "adding hijacked chargemon..."
	dd if=/data/local/tmp/chargemon.sh of=/system/bin/chargemon
	chown root.shell /system/bin/chargemon
	chmod 755 /system/bin/chargemon
else  
	# JB 4.3 or KK
	# cleaning obsolete chargemon hijack
	if [ -f /system/bin/chargemon.stock ]; then
		echo ""
		echo "restoring stock chargemon..."
		rm -f /system/bin/chargemon
		dd if=/system/bin/chargemon.stock of=/system/bin/chargemon
		rm -f /system/bin/chargemon.stock
	
		# correcting permissions
		chown root.shell /system/bin/chargemon
		chmod 755 /system/bin/chargemon
	fi

	# backup stock wipedata
	if [ ! -f /system/bin/wipedata.stock ]; then
		echo ""
		echo "backing up stock wipedata..."
		dd if=/system/bin/wipedata of=/system/bin/wipedata.stock
	fi
	# correcting permissions
	chown root.shell /system/bin/wipedata.stock
	chmod 755 /system/bin/wipedata.stock

	# adding hacked wipedata
	echo ""
	echo "adding hijacked wipedata..."
	dd if=/data/local/tmp/wipedata.sh of=/system/bin/wipedata
	chown root.shell /system/bin/wipedata
	chmod 755 /system/bin/wipedata
fi

# cleaning temp files
CLEANFILES

# verifying
echo ""
if ${IS_JB41};then
	if [ -f /system/bin/chargemon ] && [ -f /system/btmgr/philz.cpio.gz ] && [ -f /system/btmgr/twrp.cpio.gz ] && [ -f /system/btmgr/cwm.cpio.gz ] && [ -f /system/btmgr/bin/busybox ];then
		echo "Philz Touch, CWM Touch and TWRP successfully installed!"
	else
		echo "Something goes wrong, exiting"
	fi
else
	if [ -f /system/bin/wipedata ] && [ -f /system/btmgr/philz.cpio.gz ] && [ -f /system/btmgr/twrp.cpio.gz ] && [ -f /system/btmgr/cwm.cpio.gz ] && [ -f /system/btmgr/bin/busybox ];then
		echo "Philz Touch, CWM Touch and TWRP successfully installed!"
	else
		echo "Something goes wrong, exiting"
	fi
fi

echo " "
echo "              [ all done! ] "
echo " "

# remounting system as read only
mount -o remount, ro /system
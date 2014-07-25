#!/bin/sh

#Change if changing tree
tree=4.4-autobuild

git remote update
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/"$tree")
BASE=$(git merge-base HEAD origin/"$tree")

#Developer mode
devmode=y

#Change if changing kernel
kernel="AOSP"
config="custom_hammerhead_defconfig"
cmdline="console=ttyHSL0,115200,n8 androidboot.hardware=hammerhead user_debug=31 msm_watchdog_v2.enable=1"

export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-
ramdisk=ramdisk
kerneltype="zImage-dtb"
jobcount="-j$(grep -c ^processor /proc/cpuinfo)"
build=~/www/37.143.9.176/"$kernel"/
export PATH=~/toolchain/bin:~/bin:$PATH
dat=`date +%d%y`
ps=2048
base=0x00000000
ramdisk_offset=0x02900000
tags_offset=0x02700000

cleanme() {
	if [ -f arch/arm/boot/"$kerneltype" ]; then
		rm -rf ozip/boot.img
		rm -rf arch/arm/boot/"$kerneltype"
		make clean && make mrproper
	fi
}

rm -rf out
mkdir out
mkdir out/tmp

build() {
	make "$config"
	make "$jobcount"
}

bootpack() {
	if [ -f arch/arm/boot/"$kerneltype" ]; then
		cp arch/arm/boot/"$kerneltype" out
		mkbootfs ramdisk | gzip > out/ramdisk.gz
		mkbootimg --kernel out/"$kerneltype" --ramdisk out/ramdisk.gz --cmdline "$cmdline" --base $base --pagesize $ps --ramdisk_offset $ramdisk_offset --tags_offset $tags_offset --output ozip/boot.img
	fi
}

zippack() {
	if [ -f ozip/boot.img ]; then
		cd ozip
		if [ -f $build/"$kernel"_F2FS_$dat.zip ]; then
			rm -rf $build/"$kernel"_F2FS_$dat.zip
		fi
		zip -r ../"$kernel"_F2FS_$dat.zip ./
		mv ../"$kernel"_F2FS_$dat.zip $build
		rm -rf out
		cd ..
	fi
}

if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
elif [ $LOCAL = $BASE ]; then
    echo "Need to pull"
    changed=y
fi

if [ "$devmode" = y ]; then
    echo "Developer mode!"
    git pull origin "$tree"
    build
    bootpack
    zippack
elif [ "$changed" = y ]; then
    git pull origin "$tree"
    cleanme
    build
    bootpack
    zippack
fi

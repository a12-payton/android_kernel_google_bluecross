#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2018 Raphiel Rollerscaperers (raphielscape)
# Copyright (C) 2018 Rama Bndan Prakoso (rama982)
# Android Kernel Build Script

username=dhinesh

# Colors makes things beautiful
export TERM=xterm

red=$(tput setaf 1)             #  red
gre=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

yellow='\033[0;33m'
white='\033[0m'

# CCACHE UMMM!!! Cooks my builds fast

if [ "$use_ccache" = "yes" ];
then
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_DIR=/home/ccache/$username
ccache -M 200G
fi

if [ "$use_ccache" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/home/ccache/$username
ccache -C
export USE_CCACHE=1
ccache -M 200G
wait
echo -e ${gre}"CCACHE Cleared"${txtrst};
fi

echo
echo "Clean Build Directory"
echo 

make clean && make mrproper

rm -rf  out/goldust.zip

echo
echo "Issue Build Commands"
echo

# Main environtment
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image
ZIP_DIR=$KERNEL_DIR/../anykernel
CONFIG=b1c1_defconfig
PATH="${KERNEL_DIR}/../clang/bin:${KERNEL_DIR}/../aarch64-linux-android-4.9/bin:${KERNEL_DIR}/../arm-linux-androideabi-4.9/bin:${PATH}"

# Export

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=$KERNEL_DIR/../aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$KERNEL_DIR/../arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export LD_LIBRARY_PATH=$KERNEL_DIR/../clang/lib64:$LD_LIBRARY_PATH

export KBUILD_BUILD_USER="cool585"

# Build start
Start=$(date +"%s")

make O=out $CONFIG
make -j"$jobs" O=out \
               ARCH=arm64 \
               CC=clang \
               CLANG_TRIPLE=aarch64-linux-gnu- \
               CROSS_COMPILE=aarch64-linux-android- | tee build.log

exit_code=$?
End=$(date +"%s")
Diff=$(($End - $Start))

if [ -f $KERN_IMG ]; then
	mkdir -p $ZIP_DIR
	cp -f ./out/arch/arm64/boot/Image $ZIP_DIR/Image.gz
	cp -f ./out/arch/arm64/boot/dts/qcom/sdm845-v2.dtb $ZIP_DIR/dtb
	cp -f ./out/arch/arm64/boot/dtbo.img $ZIP_DIR/dtbo.img
	which avbtool &>/dev/null && python2 `which avbtool` add_hash_footer \
		--partition_name dtbo \
		--partition_size $((32 * 1024 * 1024)) \
		--image $ZIP_DIR/dtbo.img
	echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
else
	echo -e "$red << Failed to compile Image.gz-dtb, fix the errors first >>$white"
	exit $exit_code
fi

cd $ZIP_DIR
make clean &>/dev/null
make normal &>/dev/null
rm -rf goldust.zip

zip -r9 goldust.zip * -x .git README.md *placeholder

echo -e "$gre || Flashable zip generated under $ZIP_DIR. ||"

cp -f goldust.zip $KERNEL_DIR/out/goldust.zip
wait
echo -e "$yellow ||  moved zip to out dir || "${txtrst}

cd ..
# Build end

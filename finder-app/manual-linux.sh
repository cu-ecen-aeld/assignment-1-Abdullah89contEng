#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aesd-autograder
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(aarch64-none-linux-gnu-gcc -print-sysroot)
APPDIR=$PWD

export ARCH
export CROSS_COMPILE
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$PWD/$1
	echo "Using passed directory ${OUTDIR} for output"
fi
if [ -d $OUTDIR ]
then 
    echo "folder is alreay created"
    STATUS=0
else
    mkdir -p ${OUTDIR}
    STATUS=$?
fi

if [ $STATUS != 0 ]
then
    echo "fail to creat the passed Directory"
    exit STATUS
fi

cd "$OUTDIR"
if [[ ! -d "${OUTDIR}/linux-stable" ]]
then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    #export ARCH
    #export CROSS_COMPILE
    #make clean
    make  defconfig
    #sed -i 's/^YYLTYPE yylloc;/extern YYLTYPE yylloc;/' ${OUTDIR}/scripts/dtc/dtc-lexer.lex.c
    make -j4 all
    make modules
    make dtbs
fi

echo "Adding the Image in outdir"
sudo cp -f ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR} 
echo "Creating the staging directory for the root filesystem"
 
cd "$OUTDIR"

if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi
mkdir -p ${OUTDIR}/rootfs/{bin,sbin,lib,slib,usr/{bin,sbin,lib},tmp,dev,home,etc,var/log,sys,proc}
STATUS=$?
if [[ !${STATUS} -eq 0 ]]
then
    echo "can't creat rootfs directory"
    exit ${STATUS}
fi
ROOTFS=${OUTDIR}/rootfs
# TODO: Create necessary base directories
cd $OUTDIR/linux-stable
#sudo make INSTALL_MOD_PATH=${ROOTFS} modules_install

cd "$OUTDIR"

if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    
    #export CONFIG_PREFIX=${OUTDIR}/rootfs/usr/bin
    make clean
    make  defconfig
else
    cd busybox
fi

make clean
make defconfig

echo $PATH
sudo make -j4 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${ROOTFS} PATH=$PATH install
sudo mknod -m 666 ${ROOTFS}/dev/null c 1 3
sudo mknod -m 600 ${ROOTFS}/dev/console c 5 1
sudo touch ${ROOTFS}/etc/fstab
#sudo mount -t proc proc ${ROOTFS}/proc
#sudo mount -t sysfs sysfs ${ROOTFS}/sys


BUSYBOXEXEC=$(find ${OUTDIR}/busybox -type f -executable -name "busybox")
echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${ROOTFS}/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${ROOTFS}/bin/busybox | grep "Shared library"



# TODO: Add library dependencies to rootfs

# INTERPRETER=$(${CROSS_COMPILE}readelf -a $BUSYBOXEXEC | grep "program interpreter" | cut -d ":" -f2 | cut -d "]" -f1)
# SHAREDLIBS=$(${CROSS_COMPILE}readelf -a $BUSYBOXEXEC | grep "Shared library" | cut -d "[" -f2 | cut -d "]" -f1)
# ALLLIBS="$INTERPRETER $SHAREDLIBS"
# for LIB in $ALLLIBS;
# do
#     LIB=$(find $SYSROOT -name "$(basename $LIB)" | sed -r 's/ //g')
#     REALLIB=$(readlink -f $LIB | sed -r 's/ //g')
#     sudo cp -anLpv ${LIB} ${REALLIB} "${OUTDIR}/rootfs/lib"
# done

# TODO: Make device nodes

# TODO: Clean and build the writer utility
cd  ${APPDIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp --parent {finder.sh,conf/username.txt,finder-test.sh,writer,autorun-qemu.sh,dependencies.sh,autorun-qemu.sh} ${ROOTFS}/home
sudo cp -ar ../conf ${OUTDIR}/rootfs/conf
sudo chown -R root:root ${ROOTFS}
# TODO: Chown the root directory
# TODO: Create initramfs.cpio.gz
cd ${ROOTFS}
sudo mkdir lib64
sudo cp -avr ${SYSROOT}{/lib64/libm.so.6,/lib64/libm-2.33.so,/lib64/libresolv.so.2,/lib64/libresolv-2.33.so,/lib64/libc.so.6,/lib64/libc-2.33.so,/lib64/ld-2.33.so} ./lib64/
sudo cp -avr ${SYSROOT}/lib/ld-linux-aarch64.so.1 ./lib/
find . | sudo cpio -o -H newc  > ../initramfs.cpio
cd ..
gzip -f initramfs.cpio

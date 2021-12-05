#!/bin/bash

OS_IMAGE=/home/peter/Downloads/iso/2021-10-30-raspios-bullseye-arm64.img
WI_FI_CONFIG=/tmp/wpa_supplicant.conf
SD_CARD_DEVICE=/dev/sda
SD_CARD_PARTITION_BOOT=/dev/sda1
# rootfs is present only if the SD card already has OS installed on it
SD_CARD_PARTITION_ROOTFS=/dev/sda2
BOOT_PARTITION_MOUNT_POINT=/mnt/sd/boot

##########
echo -n "1. If the SD card is mounted, unmount it ... "
if findmnt $SD_CARD_PARTITION_BOOT >/dev/null; then
    if umount $SD_CARD_PARTITION_BOOT; then
        echo "Unmounted $SD_CARD_PARTITION_BOOT"
    else
        echo "Error while unmounting $SD_CARD_PARTITION_BOOT"
        exit 1
    fi
else
    echo "Boot partition is not mounted"
fi

if findmnt $SD_CARD_PARTITION_ROOTFS >/dev/null; then
    if umount $SD_CARD_PARTITION_ROOTFS; then
        echo "Unmounted $SD_CARD_PARTITION_ROOTFS"
    else
        echo "Error while unmounting $SD_CARD_PARTITION_ROOTFS"
        exit 1
    fi
else
    echo "Rootfs partition is not mounted"
fi

##########
echo "2. Copying OS image to SD card ... "
if dd bs=4M if=$OS_IMAGE of=$SD_CARD_DEVICE status=progress conv=fsync; then
    echo "Copied OS image"
else
    echo "Error while copying"
    exit 1
fi

if sync; then
    echo "Flushed all changes to SD card"
else
    echo "Error while flushing"
    exit 1
fi

##########
echo -n "3. Mounting boot partition ... "
mkdir -p $BOOT_PARTITION_MOUNT_POINT
if mount $SD_CARD_PARTITION_BOOT $BOOT_PARTITION_MOUNT_POINT; then
    echo "Mounted $SD_CARD_PARTITION_BOOT to $BOOT_PARTITION_MOUNT_POINT"
else
    echo "Error while mounting $SD_CARD_PARTITION_BOOT"
    exit 1
fi

##########
echo -n "4. Setting up SSH ... "
if touch /mnt/sd/boot/ssh; then
    echo "Enabled SSH"
else
    echo "Error while creating SSH file on SD card"
    exit 1
fi

##########
echo -n "5. Setting up WiFi ... "
if cp $WI_FI_CONFIG /mnt/sd/boot/; then
    echo "Copied WiFi config to SD card"
else
    echo "Error while copying WiFi config to SD card"
    exit 1
fi

##########
echo -n "6. Unmounting ... "
if umount $SD_CARD_PARTITION_BOOT; then
    echo "Unmounted SD card"
else
    echo "Error while unmounting $SD_CARD_PARTITION_BOOT"
    exit 1
fi

echo "Ready! SD card can be removed"

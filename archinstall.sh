#!/bin/bash

pause ()
{
	read -n 1 -s -r -p "Press any key to continue"
}
echo "Archinstaller beta-UNTESTED"
#data collection
if [ -d /sys/firmware/efi/efivars/ ]
then
	systemType="uefi"
	echo "SystemType: UEFI"
else
	systemType="bios"
	echo "SystemType: BIOS/UEFI-CSM"
fi

#Checking for internet connection
ping archlinux.org -c 4 -q
if [ $? = "0" ]
then
	echo "Connected to internet: Yes"
else
	echo "Connected to internet: No"
	echo "Cannot continue."
	exit 1
fi
#Updating system clock
timedatectl set-ntp true
echo Updated system clock
# Getting info
echo "What country do you want to have mirrors from?"
echo "[ ex. pl ]"
read mirrors
echo "What drive do you want to install arch to"
echo "[ /dev/sdX ]"
read drive
echo "Is it a NVME drive?"
echo "[yes, no]"
read isNVME
echo "What kernel do you want to use"
echo "[ linux, linux-lts, linux-zen, linux-hardened ]"
read kernel
rm /etc/pacman.d/mirrorlist
reflector -c $mirrors >> /etc/pacman.d/mirrorlist
pacman -Sy 

if [ $systemType = "uefi" ]
then
	if [ $isNVME = "yes" ] then
		part1="p1"
		part2="p2"
		part3="p3"
	else
		part1="1"
		part2="2"
		part3="3"
	fi
	parted -s $drive \
		mklabel gpt \
		mkpart EFI fat32 1MiB 512MiB \
		set 1 esp on \
		mkpart SWAP linux-swap 512MiB 4.5GiB \
		mkpart MAIN ext4 4.5GiB 100%
	
	mkfs.fat -F 32 $drive$part1
	mkswap $drive$part2
	mkfs.ext4 $drive$part3
	mkdir /mnt/boot
	mount $drive$part1 /mnt/boot
	swapon $drive$part2
	mount $drive$part3 /mnt
elif [ $systemType = "bios" ]
then
	part1="1"
	part2="2"
	parted -s $drive \
		mklabel msdos \
		mkpart primary linux-swap 1MiB 4GiB \
		mkpart primary ext4 4GiB 100% \
		set 2 boot on
	mkswap $drive$part1
	swapon $drive$part1
	mkfs.ext4 $drive$part2
	mount $drive$part2 /mnt
fi

pacstrap /mnt base base-devel $kernel $kernel-headers linux-firmware nano vim networkmanager man-db man-pages texinfo grub sudo efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
mkdir /mnt/usr/share/archinstaller
cp ./scripts/* /mnt/usr/share/archinstaller/
echo "Running script in chroot."
arch-chroot /mnt sh /usr/share/archinstaller/chroot.sh

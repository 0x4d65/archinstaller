#!/bin/bash

pause ()
{
	read -n 1 -s -r -p "Press any key to continue"
}

#data collection
if [ -d /sys/firmware/efi/efivars/ ]
then
	systemType="uefi"
else
	systemType="bios"
fi

echo "System type: $systemType"

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
echo "Updating mirrors"
echo "What country do you want to have mirrors from?"
echo "[ ex. us ]"
read mirrors
reflector -f 10 -c $mirrors
pacman -Sy 
echo "Type path to device that you want to install arch to"
echo "[ /dev/sdX ]"
read drive
echo "Enter swap size, in GiB" 
echo "[ ex. 2 ]"
read swapsize
if [ $systemType = "uefi" ]
then
	part1 = "1"
	part2 = "2"
	part3 = "3"
	parted -s $drive \
		mklabel gpt
		mkpart EFI fat32 1MiB 512MiB \
		set 1 esp on \
		mkpart SWAP linux-swap 512MiB $swapsize.5GiB \
		mkpart MAIN ext4 $swapsize.5GiB 100%
	
	mkfs.fat -F 32 $drive$part1
	mkswap $drive$part2
	mkfs.ext4 $drive$part3
	mount $drive$part1 /mnt/boot
	swapon $drive$part2
	mount $drive$part3 /mnt
elif [ $systemType = "bios" ]
then
	part1 = "1"
	part2 = "2"
	parted -s $drive \
		mklabel msdos \
		mkpart primary linux-swap 1MiB $swapsize \
		mkpart primary ext4 $swapsize 100% \
		set 2 boot on
	mkswap $drive$part1
	swapon $drive$part1
	mkfs.ext4 $drive$part2
	mount $drive$part2 /mnt
fi
echo "What kernel do you want to use"
echo "[ package name ex. linux-lts if unsure use 'linux']"
read kernel
pacstrap /mnt base base-devel $kernel $kernel-headers linux-firmware nano vim networkmanager man-db man-pages texinfo grub sudo 
genfstab -U /mnt >> /mnt/etc/fstab
echo "Where do you live?"
echo "[ ex. Europe/Warsaw, US/Arizona ]"
read locale
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$locale /etc/localtime
arch-chroot /mnt hwclock --systohc
mkdir /mnt/usr/share/archinstaller
cp ./chroot.sh /mnt/usr/share/archinstaller/
echo "Installing bootloader"
echo "Running script in chroot."
arch-chroot /mnt sh /usr/share/archinstaller/chroot.sh $drive $systemType

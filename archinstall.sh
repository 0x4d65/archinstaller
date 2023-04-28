#!/bin/bash

pacman -S libnewt --noconfirm --needed
wtbacktitle="archinstall"
#wtinputfix="3>&1 1>&2 2>&3"
pause ()
{
	read -n 1 -s -r -p "Press any key to continue"
}
echo "Archinstaller TUI"
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
	whiptail --msgbox "Not connected to internet! Cannot continue." 8 30 --title "ERROR!" --backtitle $wtbacktitle
	exit 1
fi
#Updating system clock
timedatectl set-ntp true
echo Updated system clock
# Getting info
echo "What country do you want to have mirrors from?"
echo "[ ex. pl ]"
mirrors=$(whiptail --inputbox "Where do you want your mirrors from: " 8 40 us --title Mirrors --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
echo "What drive do you want to install arch to"
echo "[ /dev/sdX ]"
drive=$(whiptail --inputbox "Enter target device path: " 8 30 /dev/sda --title Disk --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
echo "Is it a NVME drive?"
echo "[yes, no]"
if (whiptail --yesno "Is your drive nvme or emmc?" 8 35 --title Disk --backtitle $wtbacktitle) then
	isNVME="yes"
else
	isNVME="no"
fi
echo "What kernel do you want to use"
echo "[ linux, linux-lts, linux-zen, linux-hardened ]"
kernel=$(whiptail --inputbox "Enter the kernel package name: " 8 40 linux --title Kernel --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
rm /etc/pacman.d/mirrorlist
reflector -p "http,https" -c $mirrors >> /etc/pacman.d/mirrorlist
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 5/" /etc/pacman.conf
sed -i "s/#Color/Color/" /etc/pacman.conf
pacman -Sy 

if [ $systemType = "uefi" ]
then
	if [ $isNVME = "yes" ] 
	then
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
	
	swapon $drive$part2
	mount $drive$part3 /mnt
	mkdir /mnt/boot
	mount $drive$part1 /mnt/boot
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

pacstrap -K /mnt base base-devel "$kernel" $kernel-headers linux-firmware nano vim networkmanager man-db man-pages texinfo grub sudo efibootmgr libnewt
genfstab -U /mnt >> /mnt/etc/fstab
mkdir /mnt/usr/share/archinstaller
cp ./scripts/* /mnt/usr/share/archinstaller/
echo "Running script in chroot."
arch-chroot /mnt sh /usr/share/archinstaller/chroot.sh

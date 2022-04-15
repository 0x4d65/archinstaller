wtbacktitle="chroot-archinstall"
# ASK
echo "Set your timezone"
tzselect | cat >> ./tz.tmp
timezone=`cat ./tz.tmp`
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
#
echo "Hostname"
echo "[ ex. mycomputer ]"
hostname=$(whiptail --inputbox "Hostname: " 8 30 localhost --title Hostname --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
echo $hostname >> /etc/hostname
#
echo "Keymap"
echo "[ ex. us ]"
keymap=$(whiptail --inputbox "Keymap: " 8 30 us --title Keymap --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
echo KEYMAP=$keymap >> vconsole.conf
#
echo "System type"
echo "[UEFI, BIOS]"
systype=$(whiptail --menu "System type:" 10 20 2 UEFI "" BIOS "" --title "System type" --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
#
echo "Language"
echo "[ ex. pl_PL ]"
lang=$(whiptail --inputbox "Language: " 8 30 en_US --title Lang --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
if [ $lang != en_US ]
then
    sed -i "s/#$lang.UTF-8 UTF-8/$lang.UTF-8 UTF-8/" /etc/locale.gen
fi
locale-gen
echo LANG=$lang.UTF-8 >> /etc/locale.conf
#
echo "What drive to install the bootloader to?"
echo "[ /dev/sdX ]"
drive=$(whiptail --inputbox "Enter target device path: " 8 30 /dev/sda --title Bootloader --backtitle $wtbacktitle 3>&1 1>&2 2>&3)

#
echo "Set root password"
echo "Setting password for user: root"
passwd
#
echo "Make a new user"
echo "Username"
username=$(whiptail --inputbox "Username: " 8 30 user --title Username --backtitle $wtbacktitle 3>&1 1>&2 2>&3)
useradd -m $username -G wheel
echo "Setting password for user: $username"
passwd $username  
# DO
pacman -Sy intel-ucode amd-ucode --noconfirm
systemctl enable NetworkManager
echo "Installing a bootloader"
if (whiptail --yesno "Is your system using UEFI" 7 30 --title "System type" --backtitle $wtbacktitle)
then
    grub-install $drive --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else
    grub-install $drive --target=i386-pc
    grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "Instalation finished!"

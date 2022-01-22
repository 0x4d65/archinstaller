# ASK
echo "Set your timezone"
tzselect | cat >> ./tz.tmp
timezone=`cat ./tz.tmp`
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
#
echo "Hostname"
echo "[ ex. mycomputer ]"
read hostname
echo $hostname >> /etc/hostname
#
echo "Keymap"
echo "[ ex. us ]"
read keymap
echo KEYMAP=$keymap >> vconsole.conf
#
echo "Language"
echo "[ ex. pl_PL ]"
read lang
if [ $lang != en_US ]
then
    sed -i "s/#$lang.UTF-8 UTF-8/$lang.UTF-8 UTF-8/" /etc/locale.gen
fi
locale-gen
echo LANG=$lang.UTF-8 >> /etc/locale.conf
#
echo "What drive to install the bootloader to?"
echo "[ /dev/sdX ]"
read drive
#
echo "Set root password"
passwd
#
echo "Make a new user"
echo "Username"
read username
useradd -m $username -G wheel
echo "Password"
passwd $username  
# DO
pacman -Sy intel-ucode amd-ucode --noconfirm
systemctl enable NetworkManager.service
echo "Installing a bootloader"
if [ -d /sys/firmware/efi/efivars ]
then
    grub-install $drive --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else
    grub-install $drive --target=i386-pc
    grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "Instalation finished!"

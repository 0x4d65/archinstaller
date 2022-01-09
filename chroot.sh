drive = $1
systype = $2
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /etc/locale.gen
echo "Language"
echo "[ ex. pl_PL ]"
read lang 
sed -i "s/#$lang.UTF-8 UTF-8/$lang.UTF-8 UTF-8" /etc/locale.gen
locale-gen
localectl set-locale $lang.UTF-8
echo "Hostname"
echo "[ ex. mycomputer ]"
read hostname
hostnamectl set-hostname $hostname
echo "Keymap"
echo "[ ex. us ]"
read keymap
localectl set-keymap $keymap
echo "Rebuilding initramfs"
mkinitcpio -p 
echo "Set root password"
passwd 
pacman -Sy intel-ucode amd-ucode --noconfirm
systemctl enable NetworkManager.service
echo "Installing a bootloader"
if [ systype = "uefi" ]
then
    echo "Installing grub for uefi"
    grub-install --target=x86_64-efi --efi-directory /boot/
    grub-mkconfig -o /boot/grub/grub.cfg
elif [ systype = "bios" ]
then 
    echo "Installing grub for bios"
    grub-install --target=i386-pc 
    grub-mkconfig -o /boot/grub/grub.cfg
fi
echo "Make a new user"
echo "Username"
read username
useradd -m $username -G wheel
echo "Password"
passwd $username
echo "Instalation finished!"

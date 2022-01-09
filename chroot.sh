
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo "Language"
echo "[ ex. pl_PL ]"
read lang 
sed -i "s/#$lang.UTF-8 UTF-8/$lang.UTF-8 UTF-8/" /etc/locale.gen
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
echo "What drive to install the bootloader to?"
echo "[ /dev/sdX ]"
read drive
grub-install $drive
grub-mkconfig -o /boot/grub/grub.cfg
echo "Make a new user"
echo "Username"
read username
useradd -m $username -G wheel
echo "Password"
passwd $username
echo "Instalation finished!"

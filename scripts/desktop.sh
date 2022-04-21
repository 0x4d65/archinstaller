desktop=$(whiptail --title "Desktop" --menu Desktop 12 40 6 xfce4 "XFCE desktop enviroment" gnome "GNOME desktop enviroment" plasma "KDE plasma desktop" lxde "LXDE desktop" lxqt "LXQT desktop" 3>&1 1>&2 2>&3)
echo $desktop
pacman -S --noconfirm $desktop gnome-background --needed
if [ $desktop = "plasma" ]
then
	pacman -S --noconfirm --needed konsole ark dolphin
fi
dm=$(whiptail --title "DM" --menu DM 12 40 4 lightdm "LightDM" sddm "SDDM" lxdm "LXDM" "" "None" 3>&1 1>&2 2>&3)
pacman -S --noconfim $dm
systemctl enable $dm
if [ $dm = "lightdm" ]
then
	pacman -S --noconfirm lightdm-gtk-greeter
fi


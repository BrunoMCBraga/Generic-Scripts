#Getting network
systemctl enable dhcpcd@eth0.service
ip link | grep -Po "(?<=[0-9]{1}: )[^:]+(?=:)" | dhcpcd #just dhcpcd also works
pacman -S linux-headers # Needed for the next step
pacman -S --noconfirm broadcom-wl-dkms #may not be necessary
pacman -S --noconfirm wpa_supplicant #may not be necessary

#Adding new user to sudoers
pacman -S —noconfirm sudo
useradd -m -s lbin/bash sicario
usermod -a -G wheel sicario
echo "sicario ALL=(ALL) ALL" >> /etc/sudoers
echo “sicario:sicario” | chpasswd

#Installing GUI
sudo pacman -S —noconfirm xorg-server xorg-xinit
pacman -S —noconfirm lxde ttf-dejavu # the latter 2 can be optional. XFCE default fonts suck at rendering text so you will need to install this package and then change the font on the preferences.
echo “exec startlxde” > /root/.xinitrc
echo “exec startlxde” > /home/sicario/.xinitrc

#Installing some apps
pacman -S —noconfirm chromium

#Wireless
echo "ctrl_interface=/run/wpa_supplicant\nupdate_config=1" > /etc/wpa_supplicant/wpa_supplicant.conf
for interface in `ip link | grep -Po "(?<=[0-9]{1}: )wl[^:]+(?=:)"`; do systemctl wpa_supplicant@$interface.service
